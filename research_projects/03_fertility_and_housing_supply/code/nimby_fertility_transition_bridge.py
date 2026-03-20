from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import pandas as pd


@dataclass(frozen=True)
class BridgeParams:
    T: int = 80
    J: int = 8
    fertile_idx: tuple[int, ...] = (2, 3, 4)
    leave_home_lag: int = 2
    surv: tuple[float, ...] = (0.98, 0.995, 0.995, 0.992, 0.99, 0.985, 0.97)
    f_level: float = 0.22
    f_price_semi_elasticity: float = 0.20
    theta0: float = 0.20
    theta_old: float = 0.90
    theta_young: float = 0.15
    theta_boom_nimby: float = 4.00
    nimby_lag: int = 18
    nimby_window: int = 10
    eps0: float = 0.90
    d0: float = 0.95
    d_young: float = 1.00
    d_birth: float = 0.30
    n_home_demand: float = 0.15
    s0: float = 1.00
    price_gain: float = 0.35
    age_grid: tuple[float, ...] = (15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0, 85.0)
    homeownership_base: tuple[float, ...] = (0.02, 0.35, 0.42, 0.48, 0.70, 0.76, 0.73, 0.55)
    homeownership_price_beta: tuple[float, ...] = (0.05, 0.60, 0.50, 0.35, 0.15, 0.05, 0.02, 0.00)
    family_age_exposure: tuple[float, ...] = (0.00, 0.25, 1.00, 0.75, 0.15, 0.00, 0.00, 0.00)
    lambda_crowd: float = 0.30
    psi_crowd: float = 0.60
    projection_fertile_mid_weight: float = 0.25
    projection_age_midpoints: tuple[float, ...] = (32.0, 49.5, 69.5, 80.0)


def default_mass_vector() -> np.ndarray:
    vec = np.array([0.14, 0.13, 0.14, 0.14, 0.13, 0.12, 0.11, 0.09], dtype=float)
    return vec / vec.sum()


def _clip_exp_arg(value: float) -> float:
    return float(np.clip(value, -20.0, 20.0))


def age_homeownership_proxy(params: BridgeParams, age: float, price_gap: float) -> float:
    age_grid = np.asarray(params.age_grid, dtype=float)
    if age < age_grid[0] or age > age_grid[-1]:
        return np.nan
    base_level = float(np.interp(age, age_grid, np.asarray(params.homeownership_base, dtype=float)))
    price_beta = float(np.interp(age, age_grid, np.asarray(params.homeownership_price_beta, dtype=float)))
    base_logit = np.log(base_level / (1.0 - base_level))
    return float(1.0 / (1.0 + np.exp(-(base_logit - price_beta * price_gap))))


def age_housing_burden_proxy(params: BridgeParams, age: float, price_gap: float, n_home: float) -> float:
    age_grid = np.asarray(params.age_grid, dtype=float)
    if age < age_grid[0] or age > age_grid[-1]:
        return np.nan
    family_exposure = float(np.interp(age, age_grid, np.asarray(params.family_age_exposure, dtype=float)))
    return float(np.exp(price_gap) * (1.0 + params.lambda_crowd * family_exposure * n_home) ** params.psi_crowd)


def _weighted_mean(weights: np.ndarray, values: np.ndarray) -> float:
    mask = np.isfinite(values)
    if not np.any(mask):
        return np.nan
    w = weights[mask]
    v = values[mask]
    weight_sum = float(w.sum())
    if weight_sum <= 0.0:
        return np.nan
    return float(np.dot(w, v) / weight_sum)


def attach_transition_proxies(
    df: pd.DataFrame,
    age_shares: np.ndarray,
    params: BridgeParams,
    boom_start: int = 0,
    boom_end: int = 9,
) -> pd.DataFrame:
    out = df.copy()
    price_gap = out["price"].to_numpy() - float(out["price"].iloc[0])
    age_grid = np.asarray(params.age_grid, dtype=float)
    young_idx = np.array([1, 2])
    old_idx = np.array([4, 5])

    young_proxy = []
    old_proxy = []
    aggregate_proxy = []

    for t in range(len(out)):
        age_ownership = np.array(
            [age_homeownership_proxy(params, float(age_grid[j]), float(price_gap[t])) for j in range(params.J)],
            dtype=float,
        )
        young_proxy.append(_weighted_mean(age_shares[t, young_idx], age_ownership[young_idx]))
        old_proxy.append(_weighted_mean(age_shares[t, old_idx], age_ownership[old_idx]))
        aggregate_proxy.append(_weighted_mean(age_shares[t, :], age_ownership))

    out["young_homeownership_proxy"] = young_proxy
    out["old_homeownership_proxy"] = old_proxy
    out["aggregate_homeownership_proxy"] = aggregate_proxy

    for j, age in enumerate(age_grid):
        out[f"age_share_{int(age)}"] = age_shares[:, j]

    boom_birth_year = 0.5 * (boom_start + boom_end)
    parent_birth_year = boom_birth_year - 25.0
    child_birth_year = boom_birth_year + 25.0

    for prefix, birth_year in (
        ("boom", boom_birth_year),
        ("parent", parent_birth_year),
        ("child", child_birth_year),
    ):
        ages = out["t"].to_numpy(dtype=float) - birth_year
        out[f"{prefix}_generation_age"] = ages
        out[f"{prefix}_generation_homeownership_proxy_level"] = [
            age_homeownership_proxy(params, float(age), float(gap)) for age, gap in zip(ages, price_gap)
        ]
        out[f"{prefix}_generation_housing_burden_proxy_level"] = [
            age_housing_burden_proxy(params, float(age), float(gap), float(n_home))
            for age, gap, n_home in zip(ages, price_gap, out["n_home"].to_numpy(dtype=float))
        ]

    return out


def simulate_baby_boom(
    params: BridgeParams,
    mode: str,
    damping: float = 0.25,
    boom_amp: float = 0.10,
    boom_start: int = 0,
    boom_end: int = 9,
) -> pd.DataFrame:
    if mode not in {"fertility", "old_proxy"}:
        raise ValueError(f"Unsupported mode: {mode}")

    mass = np.zeros((params.T + 1, params.J), dtype=float)
    mass[0, :] = default_mass_vector()

    prices = np.zeros(params.T + 1, dtype=float)
    births = np.zeros(params.T, dtype=float)
    fertility = np.zeros(params.T, dtype=float)
    theta = np.zeros(params.T, dtype=float)
    young = np.zeros(params.T, dtype=float)
    old = np.zeros(params.T, dtype=float)
    average_age = np.zeros(params.T, dtype=float)
    n_home = np.zeros(params.T, dtype=float)
    age_shares = np.zeros((params.T, params.J), dtype=float)
    lagged_births = np.zeros(params.leave_home_lag + 1, dtype=float)
    nimby_birth_hist = np.zeros(params.nimby_lag + params.nimby_window, dtype=float)

    fertile0 = max(float(mass[0, list(params.fertile_idx)].sum()), 1e-9)
    fixed_births = params.f_level * fertile0
    surv = np.asarray(params.surv, dtype=float)
    age_grid = np.asarray(params.age_grid, dtype=float)

    for t in range(params.T):
        current_mass = mass[t, :]
        young[t] = float(current_mass[0] + current_mass[1])
        old[t] = float(current_mass[5] + current_mass[6] + current_mass[7])
        average_age[t] = float(np.dot(current_mass, age_grid))
        age_shares[t, :] = current_mass

        fertile_mass = max(float(current_mass[list(params.fertile_idx)].sum()), 1e-9)
        n_home_proxy = float(lagged_births[:-1].sum())
        n_home[t] = n_home_proxy

        boom_mult = 1.0 + boom_amp if boom_start <= t <= boom_end else 1.0

        if mode == "fertility":
            f_arg = _clip_exp_arg(-params.f_price_semi_elasticity * prices[t])
            desired_f = float(np.clip(params.f_level * np.exp(f_arg), 0.05, 0.85))
            births[t] = desired_f * fertile_mass * boom_mult
        else:
            births[t] = fixed_births * boom_mult
        fertility[t] = births[t] / fertile_mass

        nimby_window = nimby_birth_hist[params.nimby_lag : params.nimby_lag + params.nimby_window]
        nimby_entrants = float(nimby_window.mean())
        theta_raw = (
            params.theta0
            + params.theta_old * old[t]
            - params.theta_young * young[t]
            + params.theta_boom_nimby * nimby_entrants
        )
        theta[t] = float(np.clip(theta_raw, 0.0, 0.95))

        demand = params.d0 + params.d_young * young[t]
        if mode == "fertility":
            demand += params.d_birth * births[t] + params.n_home_demand * n_home_proxy
        supply = params.s0 + params.eps0 * (1.0 - theta[t]) * np.exp(_clip_exp_arg(-prices[t]))
        desired = prices[t] + params.price_gain * (demand - supply)
        prices[t + 1] = float(np.clip((1.0 - damping) * prices[t] + damping * desired, -6.0, 6.0))

        mass[t + 1, 0] = births[t]
        for j in range(1, params.J):
            mass[t + 1, j] = surv[j - 1] * current_mass[j - 1]
        row_sum = float(mass[t + 1, :].sum())
        if row_sum > 0.0:
            mass[t + 1, :] /= row_sum

        lagged_births = np.concatenate(([births[t]], lagged_births[:-1]))
        nimby_birth_hist = np.concatenate(([births[t]], nimby_birth_hist[:-1]))

    df = pd.DataFrame(
        {
            "t": np.arange(params.T, dtype=int),
            "price": prices[:-1],
            "births": births,
            "fertility_rate": fertility,
            "young_share": young,
            "old_share": old,
            "theta": theta,
            "average_age": average_age,
            "n_home": n_home,
        }
    )
    return attach_transition_proxies(df, age_shares, params, boom_start=boom_start, boom_end=boom_end)


def summarize_transition(base: pd.DataFrame, shock: pd.DataFrame, post_start: int = 40) -> dict[str, float]:
    post_mask = shock["t"] >= post_start
    boom_mask = (shock["t"] >= 0) & (shock["t"] <= 9)

    price_index_base = np.exp(base["price"] - float(base["price"].iloc[0]))
    price_index_shock = np.exp(shock["price"] - float(shock["price"].iloc[0]))
    young_dev = shock["young_homeownership_proxy"] - base["young_homeownership_proxy"]
    old_dev = shock["old_homeownership_proxy"] - base["old_homeownership_proxy"]
    boom_access_index = shock["boom_generation_homeownership_proxy_level"] / base["boom_generation_homeownership_proxy_level"]
    child_access_index = shock["child_generation_homeownership_proxy_level"] / base["child_generation_homeownership_proxy_level"]

    return {
        "post_price_response": float((price_index_shock - price_index_base)[post_mask].mean()),
        "peak_price_response": float((price_index_shock - price_index_base).max()),
        "young_homeownership_trough": float(young_dev.min()),
        "old_homeownership_trough": float(old_dev.min()),
        "boom_generation_access_trough": float(np.nanmin(boom_access_index)),
        "child_generation_access_trough": float(np.nanmin(child_access_index)),
        "boom_fertility_response": float((shock["fertility_rate"] - base["fertility_rate"])[boom_mask].mean()),
        "post_fertility_response": float((shock["fertility_rate"] - base["fertility_rate"])[post_mask].mean()),
    }


def _projection_excess(
    price: float,
    young_share: float,
    old_share: float,
    fertile_mass: float,
    n_home_proxy: float,
    params: BridgeParams,
    mode: str,
) -> tuple[float, float, float, float]:
    theta_raw = params.theta0 + params.theta_old * old_share - params.theta_young * young_share
    theta = float(np.clip(theta_raw, 0.0, 0.95))

    if mode == "fertility":
        f_arg = _clip_exp_arg(-params.f_price_semi_elasticity * price)
        desired_f = float(np.clip(params.f_level * np.exp(f_arg), 0.05, 0.85))
        births = desired_f * fertile_mass
        demand = params.d0 + params.d_young * young_share + params.d_birth * births + params.n_home_demand * n_home_proxy
    elif mode == "nimby_proxy":
        desired_f = params.f_level
        births = desired_f * fertile_mass
        demand = params.d0 + params.d_young * young_share
    else:
        raise ValueError(f"Unsupported projection mode: {mode}")

    supply = params.s0 + params.eps0 * (1.0 - theta) * np.exp(_clip_exp_arg(-price))
    return float(demand - supply), float(births), float(desired_f), theta


def _solve_projection_price(
    young_share: float,
    old_share: float,
    fertile_mass: float,
    n_home_proxy: float,
    params: BridgeParams,
    mode: str,
) -> tuple[float, float, float, float]:
    lo = -6.0
    hi = 6.0
    f_lo, _, _, _ = _projection_excess(lo, young_share, old_share, fertile_mass, n_home_proxy, params, mode)
    f_hi, _, _, _ = _projection_excess(hi, young_share, old_share, fertile_mass, n_home_proxy, params, mode)

    if np.sign(f_lo) == np.sign(f_hi):
        grid = np.linspace(lo, hi, 241)
        best_price = lo
        best_gap = np.inf
        best_births = 0.0
        best_fert = 0.0
        best_theta = 0.0
        for price in grid:
            gap, births, fert, theta = _projection_excess(price, young_share, old_share, fertile_mass, n_home_proxy, params, mode)
            if abs(gap) < best_gap:
                best_gap = abs(gap)
                best_price = float(price)
                best_births = births
                best_fert = fert
                best_theta = theta
        return best_price, best_births, best_fert, best_theta

    for _ in range(80):
        mid = 0.5 * (lo + hi)
        f_mid, births_mid, fert_mid, theta_mid = _projection_excess(
            mid, young_share, old_share, fertile_mass, n_home_proxy, params, mode
        )
        if abs(f_mid) < 1e-10 or (hi - lo) < 1e-8:
            return float(mid), births_mid, fert_mid, theta_mid
        if np.sign(f_mid) == np.sign(f_lo):
            lo = mid
            f_lo = f_mid
        else:
            hi = mid
            f_hi = f_mid

    mid = 0.5 * (lo + hi)
    _, births_mid, fert_mid, theta_mid = _projection_excess(mid, young_share, old_share, fertile_mass, n_home_proxy, params, mode)
    return float(mid), births_mid, fert_mid, theta_mid


def simulate_projection_bridge(
    age_path: pd.DataFrame,
    params: BridgeParams,
    mode: str = "fertility",
) -> pd.DataFrame:
    required = {"year", "scenario", "share_25_39", "share_40_59", "share_60_79", "share_80"}
    missing = required.difference(age_path.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    rows: list[pd.DataFrame] = []
    age_mid = np.asarray(params.projection_age_midpoints, dtype=float)

    for scenario, group in age_path.sort_values("year").groupby("scenario", sort=False):
        years = group["year"].to_numpy(dtype=int)
        share_25_39 = group["share_25_39"].to_numpy(dtype=float)
        share_40_59 = group["share_40_59"].to_numpy(dtype=float)
        share_60_79 = group["share_60_79"].to_numpy(dtype=float)
        share_80 = group["share_80"].to_numpy(dtype=float)

        prices = np.zeros(len(group), dtype=float)
        births = np.zeros(len(group), dtype=float)
        fertility = np.zeros(len(group), dtype=float)
        theta = np.zeros(len(group), dtype=float)
        average_age = np.zeros(len(group), dtype=float)
        young_homeownership = np.zeros(len(group), dtype=float)
        old_homeownership = np.zeros(len(group), dtype=float)
        housing_burden = np.zeros(len(group), dtype=float)
        lagged_births = np.zeros(params.leave_home_lag + 1, dtype=float)

        for t in range(len(group)):
            young_share = float(share_25_39[t])
            old_share = float(share_60_79[t] + share_80[t])
            fertile_mass = max(float(share_25_39[t] + params.projection_fertile_mid_weight * share_40_59[t]), 1e-9)
            average_age[t] = float(
                np.dot(
                    np.array([share_25_39[t], share_40_59[t], share_60_79[t], share_80[t]], dtype=float),
                    age_mid,
                )
            )
            n_home_proxy = float(lagged_births[:-1].sum())

            prices[t], births[t], fertility[t], theta[t] = _solve_projection_price(
                young_share, old_share, fertile_mass, n_home_proxy, params, mode
            )

            price_gap = float(prices[t] - prices[0]) if t > 0 else 0.0
            young_homeownership[t] = age_homeownership_proxy(params, 32.0, price_gap)
            old_homeownership[t] = age_homeownership_proxy(params, 65.0, price_gap)
            housing_burden[t] = age_housing_burden_proxy(params, 32.0, price_gap, n_home_proxy)
            lagged_births = np.concatenate(([births[t]], lagged_births[:-1]))

        frame = group.copy()
        frame["price"] = prices
        frame["price_index"] = np.exp(frame["price"] - float(frame["price"].iloc[0]))
        frame["births"] = births
        frame["fertility_rate"] = fertility
        frame["theta"] = theta
        frame["average_age_bridge"] = average_age
        frame["young_homeownership_proxy"] = young_homeownership
        frame["old_homeownership_proxy"] = old_homeownership
        frame["young_housing_burden_proxy"] = housing_burden
        rows.append(frame)

    return pd.concat(rows, ignore_index=True)
