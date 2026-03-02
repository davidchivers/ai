#include <iostream> //input output
#include <iomanip> 
#include <cmath> 
#include "nr.h"
#include <vector> 
#include <stdio.h> 
#include <time.h>
#include <math.h>
#include <stdlib.h> 
#include <assert.h> //code check, stop
#include <stdio.h>
#include <limits>
#include <fstream>
#include <algorithm>
#include <string>
#include <sstream>

#ifdef _WIN32
	#include <direct.h>
	#include <io.h>
#else
	#include <sys/stat.h>
	#include <unistd.h>
#endif


using namespace std; //standard namespace


string workingpath = "/lustre/work/econfeng/zfeng/Entr_necessary/";
string workingpath_new;

//***********//
//parameters:
//***********//

double best_check_tol = 10.0;
double underline_c;

double x_share_edu[3], k_share;
double beta, alpha_edu[3], gamma_edu[3], x_eps, alpha = 0.0, gamma_param = 0.0;             //discount, capital share, x distribution.
double psi, tau, tau_pi, tau_y, kappa;   //
double mu, bar_m; //search rate
double sigma;
const int Nm = 7;                      //grid for medical spending.

double output_opt[8];
double tfp;
double theta, q_A, b_E;
int while_stop_value, iter_agg;


//*******************//
//policy variables:
//*******************//
double agg_coins;                      //insurance channel
double dep_k;                          //depreciation rate.

double c_floor;
double tau_s, govt;
double tau_y0, tau_y1;
double t_lumpsum0, t_lumpsum1, transfer0;
double t_lumpsum_ben, agg_pi_EHI;
double agg_cfloor_transfer, n_cfloor_transfer;
//++++++++++++++++++++++++++++++
//experiments: counter-factual 
//++++++++++++++++++++++++++++++
double c_floor_adj;
double dummy_UI;                           //universal HI
double var_pE;
double ind_policy;                     //index for policy experiments
double ind_indemnity;

//++++++++++++++++++++++++++++++
//experiments: decomposition 
//++++++++++++++++++++++++++++++
double gn_decompose, gn_exp, gn_exp1, gn_exp2;
double gn_ben1, gn_ben2;
double r_decompose, r_wedge_decompose, r_wedge_exp, r_ben;

//++++++++++++++++++++++++++++++
//experiments: consumption penalty
//++++++++++++++++++++++++++++++
double penalty_threshold;      // threshold below which penalty applies
double penalty_weight;         // weight on the penalty function
bool use_consumption_penalty;  // flag to turn on/off penalty

//++++++++++++++++++++++++++++++
//experiments: fixed tax + lump-sum
//++++++++++++++++++++++++++++++
bool use_fixed_tax_rate;       // flag to fix income tax rate
double tau_y_baseline;          // baseline equilibrium tax rate (to be found from case 101)
double t_lumpsum_endogenous;    // endogenously determined lump-sum tax/transfer

double baseline_total_tax;          // total tax revenue in baseline
double baseline_UI_spending;        // UI spending in baseline (total_lower_out)
double baseline_cfloor_spending;    // consumption floor spending in baseline (c_gov_payment)
double baseline_govt_spending;      // total govt spending in baseline

//++++++++++++++++++++++++++++++
//experiments: deadweight loss
//++++++++++++++++++++++++++++++
bool use_deadweight_loss;      // flag for DWL experiments
double tau_y_dwl_multiplier;   // multiplier for tax rate in DWL experiments
double dwl_revenue;             // extra revenue collected and thrown away

//*******************//
//aggregate variables:
//*******************//
double z_agg;
double theta_ut,theta_ut_new, v_t, u_t,rho_aver,rho_aver_new; //matching
double w0, w1;                         //wage.
double r0, r1;                         //interest rate.
double r_wedge;                        //default premium.
double c_EHI0, c_EHI1;
double govt0, govt1;
double gdp0, gdp1;
double ave_earning0, ave_earning1;
double insure_rate;
double entr_ratio, a_y, k_y;
double earning_wkr, earning_entr;
double firm_size, firm_big;
double real_gdp;
double ave_welfare;

//********************//
//individual variables:
//********************//
//--household:
double x0, x1, z0, z1, m0, m1, oop_m0;
double i_occp0, i_occp1;
int i_occp_through[2];		//adding new for tran informations
double prob_theta_u, prob_theta_n, prob_rho;		//prob for u and n rho
double c0, c1;                         //consumption.
double a0, a1;                         //asset.
double i_wkr, i_entr;
int x_state, z_state;
double pi_tmp, w0_tmp, income_tmp, income_tmp_un;
double lowerincome_b;

//=====================================================
// Overrides (used for homotopy/continuation experiments)
//=====================================================
bool override_lowerincome_b = false;
double lowerincome_b_override = 0.0;
bool env_override_lowerincome_b = false;
double env_lowerincome_b = 0.0;
int env_max_iter_agg = -1;
int env_single_case = -1;
int env_rng_seed = -1;
bool rng_seed_initialized = false;
int env_vacancy_mode = 2;
double env_vacancy_floor = 1.0;
double env_vacancy_scale = 1e-3;


//--firm:
double n0, n1;
double k0, k1;
double k_star, n_star, rev_star;
double x0_credit, a0_credit, rev_credit, k_credit, n_credit;
double m0_credit;
double output_constrained[3];
double l_opt_v;                          //optimal loan taken by entr.


//****************//
//State variables:
//****************//
//dimension:
const int Na = 100;// + 100; 
const int Nx = 40;
const int Nx_iid = 1;
const int Nz = 5;
const int Ni = 3; //dim of employment status
const int Ni_hi = 3;
const int Ne = 3; //dim of edu
int i_edu_occp; // channel var for edu
//input, intp
const int Na_in = 100; //stable fixed value
const int Nx_in = 40;
const int Nz_in = 5;
double a_vec_in[Na_in], x_shk_in[Nx_in];

//index:
double a_vec[Na], x_shk[Nx][Ne];
double forNR_x_shk[Nx];
double a_l, a_h, x_l, x_h;

//shocks:
double pi_x_shk[Nx_iid][Nx][Ne];
double pi_x_inv[Nx][Ne];
double accum_x_shk[Nx_iid][Nx][Ne];

double update_value;
int N_iter;
//*****************//
//Value & policy functions:
//*****************//


double v0[Na][Nx][Ni][Ne], v1[Na][Nx][Ni][Ne];                                     //value functions: (a, x, edu)-->Value function.   
double vx[Na][Nx_iid][Ni][Ne];
double opt_occp_0[Na][Nx][Ni][Ne], opt_occp_1[Na][Nx][Ni][Ne];                     //policy function: (a, x, edu)-->occp choice.
double opt_a_0[Ni][Ni - 1][Na][Nx][Ne], opt_a_1[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->asset.
double opt_k_0[Ni][Ni - 1][Na][Nx][Ne], opt_k_1[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->loan.
double opt_n_0[Ni][Ni - 1][Na][Nx][Ne], opt_n_1[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->n demand.
double opt_rev_0[Ni][Ni - 1][Na][Nx][Ne], opt_rev_1[Ni][Ni - 1][Na][Nx][Ne];
double opt_c_0[Ni][Ni - 1][Na][Nx][Ne], opt_c_1[Ni][Ni - 1][Na][Nx][Ne];
//welfare
double v_ben[Na][Nx][Ni][Ne], cev[Na][Nx][Ni][Ne];

//pay consumption by goverment
double c_gov_pay[Ni][Ni - 1][Na][Nx][Ne];

//input
double v_in[Na_in][Nx_in][Ni][Ne];                       //value functions: (a, x, edu)-->Value function.   
double opt_occp_in[Na_in][Nx_in][Ni][Ne];                //policy function: (a, x, edu)-->occp choice.
double opt_a_in[Ni][Ni - 1][Na_in][Nx_in][Ne];           //policy function: (I, i_E, a, x, edu)-->asset.
double opt_k_in[Ni][Ni - 1][Na_in][Nx_in][Ne];           //policy function: (I, i_E, a, x, edu)-->loan.
double opt_n_in[Ni][Ni - 1][Na_in][Nx_in][Ne];           //policy function: (I, i_E, a, x, edu)-->n demand.

//find credit constrain.
double k_star_vec[Nx][Ne], n_star_vec[Nx][Ne], rev_star_vec[Nx][Ne];
double k_opt_vec[Na][Nx][Ne], n_opt_vec[Na][Nx][Ne], rev_opt_vec[Na][Nx][Ne];
//double k_opt_vec[Na][Nx], n_opt_vec[Na][Nx], rev_opt_vec[Na][Nx];

//**************************//
//Other variables:
//**************************//
// 
//Educations:
double edu_z[Ne] = { 0.0, 0.31, 0.61 };// wage premium
double edu_rho[Ne] = { 0.0383,0.0288,0.0136 };//separation rate
double edu_share[Ne] = { 0.109,0.581,0.310 };//people share
//double alpha_e[Ne] = { 0.967,1.007,1.156 };

//Tol:
double tol_v = 1e-3;
double tol_agg = 1e-4;
void policy_input();  // import the initial policy functions.
double intp_2d_in_4arg(double& x_a0, double& x_x0, int& xi_occp, int& edu_occp,
	double policy[Na_in][Nx_in][Ni][Ne]);
double intp_2d_in_6arg(double& x_a0, double& x_x0, int& edu_occp,
	int& i_x_occp, int& x_occp0,
	double policy[Ni][Ni - 1][Na_in][Nx_in][Ne]);
double update_step1;  //update r0, w0;

double prob_work_rate;
const double kVacancyStructuralMin = 1e-6;
const double kMinThetaModel51 = 0.02;

//**************************//
//Simulation:

const int Nsim_ppl = 100000;
const int Nsim_pd = 100;
int N_sim = 1;
int t_inv = 100;
double rnd_vec[Nsim_pd];
double rnd_x_shk[Nsim_pd][Nsim_ppl];
double hhd_history[Nsim_pd][9];
//print out simulation for exps.
double x0_sim[Nsim_ppl], a0_sim[Nsim_ppl], l0_sim[Nsim_ppl], n0_sim[Nsim_ppl];//change for no health
int occp0_sim[Nsim_ppl];
double a1_sim[Nsim_ppl], n_sim[Nsim_ppl], c_sim[Nsim_ppl], k0_sim[Nsim_ppl];
int i_occp0_sim[Nsim_ppl];
int z0_sim[Nsim_ppl];//change for no health
double y_sim[Nsim_ppl], cev_sim[Nsim_ppl];

int i_case;

//******************************//
double m_scale, x_scale;
//******************************//

//++++++++++++++++++++++++++++++++++++
//subroutines:
//++++++++++++++++++++++++++++++++++++

namespace {
	inline void shft3(DP& a, DP& b, DP& c, const DP d)
	{
		a = b;
		b = c;
		c = d;
	}

	inline double clamp_value(const double x, const double lower, const double upper)
	{
		return std::max(lower, std::min(x, upper));
	}

	inline double clamp_probability(const double p)
	{
		if (!std::isfinite(p)) {
			return 0.0;
		}
		return clamp_value(p, 0.0, 1.0);
	}

	inline double safe_market_gap(const double demand, const double supply)
	{
		const double avg = (demand + supply) / 2.0;
		if (!std::isfinite(avg) || fabs(avg) < 1e-10) {
			return 0.0;
		}
		const double raw_gap = (demand - supply) / avg;
		if (!std::isfinite(raw_gap)) {
			return 0.0;
		}
		// Keep update multipliers positive while still allowing large positive gaps.
		return clamp_value(raw_gap, -0.95, 10.0);
	}

	inline double safe_positive_update(const double candidate, const double fallback, const double floor_value)
	{
		if (!std::isfinite(candidate) || candidate <= floor_value) {
			return std::max(fallback, floor_value);
		}
		return candidate;
	}

	inline double build_vacancy_mass(const double v_legacy, const double structural_source)
	{
		double v_out = std::max(0.0, v_legacy);
		if (env_vacancy_mode >= 2) {
			const double v_struct = std::max(0.0, env_vacancy_scale) * std::max(0.0, structural_source);
			if (std::isfinite(v_struct)) {
				v_out = std::max(v_out, v_struct);
			}
		}
		if (env_vacancy_mode >= 1) {
			v_out = std::max(v_out, std::max(0.0, env_vacancy_floor));
		}
		if (!std::isfinite(v_out) || v_out < 0.0) {
			return 0.0;
		}
		return v_out;
	}

	inline bool parse_env_double(const char* raw, double& value)
	{
		if (raw == nullptr || *raw == '\0') {
			return false;
		}
		std::stringstream ss(raw);
		ss >> value;
		return !ss.fail() && ss.eof();
	}

	inline bool parse_env_int(const char* raw, int& value)
	{
		if (raw == nullptr || *raw == '\0') {
			return false;
		}
		std::stringstream ss(raw);
		ss >> value;
		return !ss.fail() && ss.eof();
	}

	inline void ensure_trailing_sep(std::string& path)
	{
		if (path.empty()) {
			return;
		}
		const char last = path[path.size() - 1];
		if (last != '/' && last != '\\') {
			path += "/";
		}
	}
}

void apply_runtime_overrides()
{
	const char* workingpath_env = getenv("CFV_WORKINGPATH");
	if (workingpath_env != nullptr && *workingpath_env != '\0') {
		workingpath = workingpath_env;
		ensure_trailing_sep(workingpath);
		cout << "Using CFV working path: " << workingpath << endl;
	}

	double ui_override_value = 0.0;
	if (parse_env_double(getenv("CFV_UI_REPLACEMENT"), ui_override_value)) {
		env_override_lowerincome_b = true;
		env_lowerincome_b = ui_override_value;
		lowerincome_b_override = ui_override_value;
		cout << "[override] lowerincome_b (env) = " << env_lowerincome_b << endl;
	}

	int max_iter_override_value = -1;
	if (parse_env_int(getenv("CFV_MAX_ITER_AGG"), max_iter_override_value) && max_iter_override_value > 0) {
		env_max_iter_agg = max_iter_override_value;
		cout << "[override] max_iter_agg = " << env_max_iter_agg << endl;
	}

	int single_case_override_value = -1;
	if (parse_env_int(getenv("CFV_SINGLE_CASE"), single_case_override_value) && single_case_override_value > 0) {
		env_single_case = single_case_override_value;
		cout << "[override] single_case = " << env_single_case << endl;
	}

	int rng_seed_override_value = -1;
	if (parse_env_int(getenv("CFV_RNG_SEED"), rng_seed_override_value) && rng_seed_override_value >= 0) {
		env_rng_seed = rng_seed_override_value;
		cout << "[override] rng_seed = " << env_rng_seed << endl;
	}

	int vacancy_mode_override_value = -1;
	if (parse_env_int(getenv("CFV_VACANCY_MODE"), vacancy_mode_override_value) && vacancy_mode_override_value >= 0) {
		env_vacancy_mode = vacancy_mode_override_value;
		cout << "[override] vacancy_mode = " << env_vacancy_mode << endl;
	}

	double vacancy_floor_override_value = 0.0;
	if (parse_env_double(getenv("CFV_VACANCY_FLOOR"), vacancy_floor_override_value) && vacancy_floor_override_value >= 0.0) {
		env_vacancy_floor = vacancy_floor_override_value;
		cout << "[override] vacancy_floor = " << env_vacancy_floor << endl;
	}

	double vacancy_scale_override_value = 0.0;
	if (parse_env_double(getenv("CFV_VACANCY_SCALE"), vacancy_scale_override_value) && vacancy_scale_override_value >= 0.0) {
		env_vacancy_scale = vacancy_scale_override_value;
		cout << "[override] vacancy_scale = " << env_vacancy_scale << endl;
	}
}

DP NR::brent(const DP ax, const DP bx, const DP cx, DP f(const DP),
	const DP tol, DP& xmin)
{

	const int ITMAX = 200;
	const DP CGOLD = 0.3819660;
	const DP ZEPS = numeric_limits<DP>::epsilon() * 1.0e-10;
	int iter;
	DP a, b, d = 0.0, etemp, fu, fv, fw, fx;
	DP p, q, r, tol1, tol2, u, v, w, x, xm;
	DP e = 0.0;

	a = (ax < cx ? ax : cx);
	b = (ax > cx ? ax : cx);
	x = w = v = bx;
	fw = fv = fx = f(x);
	for (iter = 0; iter < ITMAX; iter++) {
		xm = 0.5 * (a + b);
		tol2 = 2.0 * (tol1 = tol * fabs(x) + ZEPS);
		if (fabs(x - xm) <= (tol2 - 0.5 * (b - a))) {
			xmin = x;
			return fx;
		}
		if (fabs(e) > tol1) {
			r = (x - w) * (fx - fv);
			q = (x - v) * (fx - fw);
			p = (x - v) * q - (x - w) * r;
			q = 2.0 * (q - r);
			if (q > 0.0) p = -p;
			q = fabs(q);
			etemp = e;
			e = d;
			if (fabs(p) >= fabs(0.5 * q * etemp) || p <= q * (a - x) || p >= q * (b - x))
				d = CGOLD * (e = (x >= xm ? a - x : b - x));
			else {
				d = p / q;
				u = x + d;
				if (u - a < tol2 || b - u < tol2)
					d = SIGN(tol1, xm - x);
			}
		}
		else {
			d = CGOLD * (e = (x >= xm ? a - x : b - x));
		}
		u = (fabs(d) >= tol1 ? x + d : x + SIGN(tol1, d));
		fu = f(u);
		if (fu <= fx) {
			if (u >= x) a = x; else b = x;
			shft3(v, w, x, u);
			shft3(fv, fw, fx, fu);
		}
		else {
			if (u < x) a = u; else b = u;
			if (fu <= fw || w == x) {
				v = w;
				w = u;
				fv = fw;
				fw = fu;
			}
			else if (fu <= fv || v == x || v == w) {
				v = u;
				fv = fu;
			}
		}
	}
	if (iter >= ITMAX) {
		// Log warning instead of error
		//cerr << "Warning: Brent's method reached max iterations. Returning best value found." << endl;
		//cerr << "  Interval: [" << a << ", " << b << "]" << endl;
		//cerr << "  Best x: " << x << ", f(x): " << fx << endl;
		xmin = x;
		return fx;  // Return best solution found
	}
	xmin = x;
	return fx;
}

// import probs for x, z, m shocks.
void x_shk_input();
void pi_x_input();
//void pi_m_input();

//covergence tolerance for policy function iteration.
double check_value();
//covergence tolerance for policy function iteration.
bool check_agg();
void debug_opt_n_policy_tails();

void NRlocate(double xx[], int size, double x, int& j);
//interpeloate to get the next pd's value.
//vx has sum over (x',z',m')
//change for edu
double intp(double policy[Na][Nx_iid][Ni][Ne], double& a1_i, int& x_state_i, int ind_occp, int& edu_occp);

double expt_v(double& a1_i, int& x_state_i, int ind_occp, int& edu_occp)
//get the E(V(a+, x+, m+, HI+))
{
	double e_v = 0.0;

	e_v = intp(vx, a1_i, x_state_i, ind_occp, edu_occp);

	return e_v;
}

//compute the value function
//change for edu
double v_func(DP x)
{
	a1 = x;
	
	c0 = income_tmp - a1;
	
	// Smooth penalty instead of sharp discontinuity
	const double c_min = 1e-4;
	double utility;
	
	if (c0 >= c_min) {
		utility = (pow(c0, 1.0 - sigma) - 1.0) / (1.0 - sigma);
	} else {
		// Smooth extrapolation below c_min
		double u_at_cmin = (pow(c_min, 1.0 - sigma) - 1.0) / (1.0 - sigma);
		double du_at_cmin = pow(c_min, -sigma);  // derivative
		utility = u_at_cmin + du_at_cmin * (c0 - c_min) - 1000.0 * pow(c_min - c0, 2);
	}
	
	// NEW: Add consumption penalty if enabled
	if (use_consumption_penalty && c0 < penalty_threshold) {
		double penalty = -penalty_weight * pow(penalty_threshold - c0, 2);
		utility += penalty;
	}
	
	double a_prime, expt_value;
	expt_value = 0.0;
	expt_value = expt_v(a1, x_state, i_occp_through[0], i_edu_occp);
	double u_v_1 = -(utility + beta * expt_value);
	
	// Second part: calculate for unemployment income
	c0 = income_tmp_un - a1;
	
	if (c0 >= c_min) {
		utility = (pow(c0, 1.0 - sigma) - 1.0) / (1.0 - sigma);
	} else {
		// Apply same smooth penalty
		double u_at_cmin = (pow(c_min, 1.0 - sigma) - 1.0) / (1.0 - sigma);
		double du_at_cmin = pow(c_min, -sigma);
		utility = u_at_cmin + du_at_cmin * (c0 - c_min) - 1000.0 * pow(c_min - c0, 2);
	}
	
	// NEW: Add consumption penalty if enabled
	if (use_consumption_penalty && c0 < penalty_threshold) {
		double penalty = -penalty_weight * pow(penalty_threshold - c0, 2);
		utility += penalty;
	}
	
	expt_value = 0.0;
	expt_value = expt_v(a1, x_state, i_occp_through[1], i_edu_occp);
	double u_v_2 = -(utility + beta * expt_value);
	
	return prob_work_rate * u_v_1 + (1 - prob_work_rate) * u_v_2;
}


void solve_opt(double x_xx, double& x_a0, double& x_x0,
	double& x_i_occp, double en_i_occp,
	double& k_opt_in, double n_opt_in, double& rev_opt_in, double prob_rho, double prob_theta_u)
{
	a0 = x_a0;
	x0 = x_xx;
	z0 = x_x0;
	i_occp0 = x_i_occp;
	i_occp1 = en_i_occp;

	w0_tmp = w0;
	// Get lump-sum tax for this period (positive = tax, negative = transfer)
	double t_lumpsum_hhd = use_fixed_tax_rate ? t_lumpsum_endogenous : 0.0;
	
	//initalization for finding the optimum
	const DP TOL = 1.0e-12, EQL = 1.0e-10;
	bool newroot;
	int j;
	int nmin = 0;
	DP ax, bx, cx;
	DP xmin1, xmin2;
	Vec_DP amin(60);

	//change for no health

	double v_tmp_ins, a1_tmp_ins, k_tmp_ins, n_tmp_ins, rev_tmp_ins, c_tmp_ins, l_tmp_ins;
	double tmp_transfer;
	int ind_HI;
	ind_HI = 0;

	//change for new in this part individual's income have a prob for emp or unemp so we add a new input para- prob_work_rate

	//parameters for brent:
	nmin = 0;
	ax = a_l * 1.0;// al means min 0.01
	bx = x_xx;
	cx = a_h;
	if (bx > cx) {
		cx = bx + 5.0;
	}


	//*******************************************************************************************
	//worker's decision emp
	//i_occp1 means individual choose different type en/work
	if (i_occp1 == 1) { // choose to be worker

		income_tmp = (1 + r0 - dep_k) * a0 + (z0 * w0_tmp * (1 - (1 - psi) * tau_y0)) - t_lumpsum_hhd;

		income_tmp_un = (1 + r0 - dep_k) * a0 + lowerincome_b * w0_tmp - t_lumpsum_hhd;
		
		// Minimum income that makes c = underline_c feasible with a' = a_l
		//double min_income_floor = underline_c + a_l;  
		//income_tmp = max(income_tmp, min_income_floor);
		//income_tmp_un = max(income_tmp_un, min_income_floor);

		//different people may face different income
		if (i_occp0 == 1) // currently employed
		{
			cx = income_tmp;
			prob_work_rate = 1 - prob_rho;
			i_occp_through[0] = 1;
			i_occp_through[1] = 2;
		}
		else if (i_occp0 == 2) // currently unemployed
		{
			cx = income_tmp;
			prob_work_rate = prob_theta_u;
			i_occp_through[0] = 1;
			i_occp_through[1] = 2;
		}
		else if (i_occp0 == 0) // currently enterprenur
		{
			cx = income_tmp;
			prob_work_rate = prob_theta_u;
			i_occp_through[0] = 1;
			i_occp_through[1] = 2;
		}


		// SAFETY CHECK BEFORE BRENT:
		// If income is so low they cannot even afford the minimum asset grid point (a_l),
		// they are cornered. Force them to a_l and skip optimization.
		if (cx <= ax + 1e-9) {
			xmin1 = ax; // Force min assets
		}
		else {
			if (bx > cx) {
				bx = (ax + cx) / 2.0;
			}
			// Only run optimizer if we have a valid interval
			NR::brent(ax, bx, cx, v_func, TOL, xmin1);
		}

		if (nmin == 0) {
			amin[nmin++] = xmin1;
		}
		else {
			newroot = true;
			for (j = 0; j < nmin; j++) {
				if (fabs(xmin1 - amin[j]) <= (EQL * xmin1)) newroot = false;
				if (newroot) {
					amin[nmin++] = xmin1;
				}
			}
		}


		v_tmp_ins = -v_func(xmin1);
		a1_tmp_ins = xmin1;
		k_tmp_ins = 0.0;
		n_tmp_ins = 1.0;
		rev_tmp_ins = 0.0;
	}

	//entrepreneur's decision
	else if (i_occp1 == 0) { // choose to be enterprenur
		double k_opt, n_opt, rev_opt;

		//more work needed.

		k_opt = k_opt_in;
		n_opt = n_opt_in;
		rev_opt = rev_opt_in;

		l_opt_v = k_opt - (a0);

		income_tmp = (1 + r0 - dep_k) * a0 + rev_opt - tau_pi - t_lumpsum_hhd;

		income_tmp_un = (1 + r0 - dep_k) * a0 + rev_opt - tau_pi - t_lumpsum_hhd;
	
		cx = income_tmp;

		if (bx > cx) {
			bx = (ax + cx) / 2.0;
		}

		//check
		prob_work_rate = 0.5; // this probability is not actually used
		i_occp_through[0] = 0;
		i_occp_through[1] = 0;


		//solving optimal a'.
		NR::brent(ax, bx, cx, v_func, TOL, xmin1);
		if (nmin == 0) {
			amin[nmin++] = xmin1;
		}
		else {
			newroot = true;
			for (j = 0; j < nmin; j++) {
				if (fabs(xmin1 - amin[j]) <= (EQL * xmin1)) newroot = false;
				if (newroot) {
					amin[nmin++] = xmin1;
				}
			}
		}
		//end solving

		v_tmp_ins = -v_func(xmin1);
		a1_tmp_ins = xmin1;
		k_tmp_ins = k_opt;
		n_tmp_ins = n_opt;
		rev_tmp_ins = rev_opt;
		l_tmp_ins = l_opt_v;
	}//end of entr



	c_tmp_ins = income_tmp - a1_tmp_ins;
	// leading to negative consumption. Bound it at a small positive value.
	const double c_floor_numerical = 1e-6;
	if (c_tmp_ins < c_floor_numerical) {
		c_tmp_ins = c_floor_numerical;
	}

	//insurance choice:

	output_opt[0] = v_tmp_ins;
	output_opt[1] = a1_tmp_ins;
	output_opt[2] = k_tmp_ins;
	output_opt[3] = n_tmp_ins;
	output_opt[4] = ind_HI;                          //insurance decision, not relevant
	output_opt[5] = rev_tmp_ins;
	output_opt[6] = c_tmp_ins;
	//cout << "solve_opt" << endl;
}

void renew_functions();


//compute the opt. k when credit constrained:
double a_constrained_func(DP x);
double a_unconstrained_func(DP x);
void k_opt_constrained(double& a0_in, double& x0_in, double& n_in);
void find_credit_const();

//change for edu
void policy_compute()
{
	//i occp means 3 state occp 0 en 1 worker 2 unemp
	// en i occp means 2 optim choice 0 en 2 work
	//static 

	double tmp_x[3];
	double tmp_value;

	double ev_tmp_grid[Ni], pE_tmp_grid[Ni];
	double ev_tmp_wkr, ev_tmp_entr, ev_tmp_umep;

	double xx_in, prob_in;
	double a0_in, x0_in, z0_in, i_occp_in;
	int m0_in, i_occp_en, iter = 0;

	double k_opt_in, n_opt_in, rev_opt_in, v_next_time;

	double rho_edu_i;
	double income_pi = 0.0;// , new_alpha = 0.3207, new_gamma = 0.4693;

	//more work needed:
	//solve for k_star, n_star, rev_star before iteration begins:
	cout << "begin compu policy" << endl;
	find_credit_const();
	do {
		renew_functions();

		for (int i_e = 0; i_e < Ne; i_e++) {
			rho_edu_i = edu_rho[i_e];
			i_edu_occp = i_e;
			alpha = alpha_edu[i_e];
			gamma_param = gamma_edu[i_e];

			for (int i_x = 0; i_x < Nx; i_x++) {

				x0_in = (1 + edu_z[i_e]);//change for edu new wage premium
				//change for new
				k_star = k_star_vec[i_x][i_e];
				n_star = n_star_vec[i_x][i_e];
				rev_star = rev_star_vec[i_x][i_e];

				
				//change for new
				//for (int i_z = 0; i_z < Nz; i_z++) {
				for (int i_a = 0; i_a < Na; i_a++) {
					k_opt_in = k_opt_vec[i_a][i_x][i_e];
					n_opt_in = n_opt_vec[i_a][i_x][i_e];
					rev_opt_in = rev_opt_vec[i_a][i_x][i_e];

					tmp_value = 1e10;
					a0_in = a_vec[i_a];
					x_state = i_x;

					ev_tmp_wkr = 0.0;
					ev_tmp_entr = 0.0;

					//this part is cacu 2 types of individual
					for (int i_occp = 0; i_occp < Ni; i_occp++) {

						i_occp_in = i_occp;

						for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++)
						{
							i_occp_en = i_occp_e;
							xx_in = opt_a_0[i_occp][i_occp_e][i_a][i_x][i_e];
							
							solve_opt(xx_in, a0_in, x0_in, i_occp_in, i_occp_en,
								k_opt_in, n_opt_in, rev_opt_in, rho_edu_i, theta_ut);
							
							ev_tmp_grid[i_occp_en] = output_opt[0];
							opt_a_1[i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[1];
							opt_k_1[i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[2];
							opt_n_1[i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[3];
							opt_rev_1[i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[5];

							// Calculate actual consumption from household optimization
							double actual_consumption = output_opt[6];
							
							// Determine final consumption and government payment based on policy regime
							if (use_consumption_penalty && underline_c <= 0.0) {
								// REGIME 1: Pure penalty mechanism (no transfers)
								// Let penalty in utility function handle everything
								opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = actual_consumption;
								c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = 0.0;
							}
							else if (!use_consumption_penalty && underline_c > 0.0) {
								// REGIME 2: Pure transfer mechanism (baseline)
								if (actual_consumption >= underline_c) {
									opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = actual_consumption;
									c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = 0.0;
								}
								else {
									opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = underline_c;
									// === FIX 2 HERE (line ~727) ===
									double transfer_needed = underline_c - actual_consumption;
									double max_transfer = underline_c * 2.0;  // Cap at 2x the floor
									c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = min(transfer_needed, max_transfer);
									// Original was: c_gov_pay[...] = underline_c - actual_consumption;
								}
							}
							else if (use_consumption_penalty && underline_c > 0.0) {
								// REGIME 3: Both penalty AND transfers active
								if (actual_consumption >= underline_c) {
									opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = actual_consumption;
									c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = 0.0;
								}
								else {
									opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = underline_c;
									// === FIX 2 HERE (line ~739) ===
									double transfer_needed = underline_c - actual_consumption;
									double max_transfer = underline_c * 2.0;  // Cap at 2x the floor
									c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = min(transfer_needed, max_transfer);
									// Original was: c_gov_pay[...] = underline_c - actual_consumption;
								}
							}
							else {
								// REGIME 4: Neither penalty nor transfers (underline_c = 0, penalty off)
								opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = actual_consumption;
								c_gov_pay[i_occp][i_occp_e][i_a][i_x][i_e] = 0.0;
							}
						}

						ev_tmp_wkr = ev_tmp_grid[1];
						ev_tmp_entr = ev_tmp_grid[0];


						v_next_time = 0.0;
						if (ev_tmp_wkr >= ev_tmp_entr - 0.000001) {
							opt_occp_1[i_a][i_x][i_occp][i_e] = 1.0;
							v_next_time = ev_tmp_wkr;
						}

						//to be an entrepreure:
						else if (ev_tmp_wkr < ev_tmp_entr) {
							opt_occp_1[i_a][i_x][i_occp][i_e] = 0.0;
							v_next_time = ev_tmp_entr;
						}
						v1[i_a][i_x][i_occp][i_e] = v_next_time;
					}
				} //end i_a
			} //end i_x
		}
		iter += 1;
		//while_stop_value = 0;
		if (iter > N_iter) {
			while_stop_value = 1;
		}
		//check value tol
		cout << "iter times: " << iter << "   " << check_value() << "   " << theta_ut << endl;

	} while (check_value() > tol_v && while_stop_value == 0);
	cout << "policy_compute" << endl;

}

// import the random numbers.
void gen_rnd();

//x
void comp_accum_x();
double x0_rnd(double& rnd_x_in, int& x_sim_state, int& edu_occp);
double x0_rnd_intial(double& rnd_x_in, int& edu_occp);
//z
int z0_rnd(double& rnd_z_in, int& z_sim_state);
int z0_rnd_intial(double& rnd_z_in);

//2-dimentional interpolation:
double intp_2d(double& x_a0, double& x_x0, int& i_x_occp,
	int& x_occp0, int& edu_occp,
	double policy[Ni][Ni - 1][Na][Nx][Ne]);
//interpolate prob of occp. choice:
double intp_2d_opt(double& x_a0, double& x_x0, int& x_occp0, int& edu_occp,
	double policy[Na][Nx][Ni][Ne]);
//determine the actural occp. choice:
int intp_occp_sim(double& a0_in, double& x0_in, int& x_occp0, int& edu_occp);
//determine hhd's optimal choice w/ intp_2d.
double intp_opt_sim(double& a0_in, double& x0_in, int& i_x_occp, int& i_occp0_in, int& edu_occp,
	double opt_in[Ni][Ni - 1][Na][Nx][Ne]);

//print out results:


//simulate the economy
//simulate the economy
void simulation()
{
    //static
    // cause we need more output so this line is changed to sim outputline

    //current states:
    double x0_sim_tmp, a0_sim_tmp;
    int occp0_sim_tmp;
    int z0_sim_tmp, m0_sim_tmp;
    double pE0_sim_tmp;
    int i_x_prev;

    //current choices:
    double a1_sim_tmp, k0_sim_tmp, n0_sim_tmp, c0_sim_tmp;
    int i_occp0_sim_tmp;
    double rev_sim_tmp, income_sim;

    //simulation distribution:
    double m_coins_sim, oop_m0_sim;
    double tmp_x_rnd, tmp_z_rnd, tmp_m_rnd;

    //aggregate variables:
    double n_demand, n_supply;
    double asset_demand, asset_supply;
    double pE_offer_sim, pE_get_sim, pE_mkt_sim;

    double earning_sim;
    double agg_transfer, tmp_transfer;
    double agg_income;

    double tax_income, total_tax, c_gov_payment = 0.0;


    double agg_y_sim;
    int ppl_edu;
    double cacu_0 = 0.0, cacu_1 = 0.0, cacu_2 = 0.0;

    double v_t, u_t, ave_rho, cacu_1_rho = 0, random_num = 0.0;
    double total_lower_out;


    int cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;
    int entr_count = 0;
    int entr_count_edu[Ne] = { 0, 0, 0 };
    long long a0_out_of_grid_count = 0;
    long long a1_out_of_grid_count = 0;
    int n_raw_negative_count = 0, k_raw_negative_count = 0;
    int n_tail_gt_10 = 0, n_tail_gt_100 = 0, n_tail_gt_1000 = 0;
    double n_raw_min = std::numeric_limits<double>::infinity();
    double n_raw_max = -std::numeric_limits<double>::infinity();
    double k_raw_min = std::numeric_limits<double>::infinity();
    double k_raw_max = -std::numeric_limits<double>::infinity();
    double n_entr_sum = 0.0, k_entr_sum = 0.0;
    double n_entr_max = 0.0, k_entr_max = 0.0;

    if (!rng_seed_initialized) {
        if (env_rng_seed >= 0) {
            srand((unsigned int)env_rng_seed);
        }
        else {
            srand((unsigned int)time(0));
        }
        rng_seed_initialized = true;
    }

    auto education_index_from_person = [&](int ppl_sim_idx) -> int {
        if (ppl_sim_idx < edu_share[0] * Nsim_ppl) {
            return 0;
        }
        if (ppl_sim_idx < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
            return 1;
        }
        return 2;
    };

    for (int t_sim = 0; t_sim < Nsim_pd; t_sim++) {
        n_supply = 0.0;
        n_demand = 0.0;
        asset_demand = 0.0;
        pE_mkt_sim = 0.0;
        pE_offer_sim = 0.0;
        pE_get_sim = 0.0;

        earning_sim = 0.0;
        asset_demand = 0.0;
        asset_supply = 0.0;
        agg_transfer = 0.0;
        agg_income = 0.0;
        agg_cfloor_transfer = 0.0;
        n_cfloor_transfer = 0;

        agg_pi_EHI = 0;

        earning_wkr = 0.0;
        earning_entr = 0.0;

        agg_y_sim = 0.0;
        z_agg = 0.0;

        entr_ratio = 0;
        firm_size = 0.0;
        firm_big = 0.0;

        gn_ben1 = 0.0;
        gn_ben2 = 0.0;

        total_tax = 0.0;
        tax_income = 0.0;

        rho_aver_new = 0.0;
        total_lower_out = 0.0;
        c_gov_payment = 0.0;

        cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;
        entr_count = 0;
        entr_count_edu[0] = 0;
        entr_count_edu[1] = 0;
        entr_count_edu[2] = 0;
        a0_out_of_grid_count = 0;
        a1_out_of_grid_count = 0;
        n_raw_negative_count = 0;
        k_raw_negative_count = 0;
        n_tail_gt_10 = 0;
        n_tail_gt_100 = 0;
        n_tail_gt_1000 = 0;
        n_raw_min = std::numeric_limits<double>::infinity();
        n_raw_max = -std::numeric_limits<double>::infinity();
        k_raw_min = std::numeric_limits<double>::infinity();
        k_raw_max = -std::numeric_limits<double>::infinity();
        n_entr_sum = 0.0;
        k_entr_sum = 0.0;
        n_entr_max = 0.0;
        k_entr_max = 0.0;
        


        if (t_sim == 0) {
            theta_ut_new = 0.6;
            rho_aver_new = 0.03;
        }
        else {
            // cacu rho and theta

            ave_rho = 0.0;
            cacu_1_rho = 0.0;
            double expected_n_demand_pre = 0.0;

            cacu_0 = 0.0;
            cacu_1 = 0.0;
            cacu_2 = 0.0;

            for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
                ppl_edu = education_index_from_person(ppl_sim);
                a0_sim_tmp = a0_sim[ppl_sim];
                x0_sim_tmp = x0_sim[ppl_sim];
                occp0_sim_tmp = occp0_sim[ppl_sim];

                const double prob_work = clamp_probability(intp_2d_opt(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu, opt_occp_0));
                const double prob_entrepreneur = 1.0 - prob_work;
                int occp_choice_entrepreneur = 0;
                const double n_policy_raw = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, occp_choice_entrepreneur, ppl_edu, opt_n_0);
                const double n_policy = (std::isfinite(n_policy_raw)) ? std::max(0.0, n_policy_raw) : 0.0;

                cacu_0 += prob_entrepreneur;
                expected_n_demand_pre += prob_entrepreneur * n_policy;
                if (occp0_sim[ppl_sim] == 2 || occp0_sim[ppl_sim] == 0) {
                    cacu_2 += prob_work;
                }
                else if (occp0_sim[ppl_sim] == 1) {
                    const double weighted_rho = prob_work * edu_rho[ppl_edu];
                    cacu_1 += prob_work;
                    cacu_1_rho += weighted_rho;
                    ave_rho += weighted_rho;
                }

            }


            const double v_legacy_pre = cacu_1_rho;
            const double structural_source_pre = std::max(0.0, expected_n_demand_pre);
            const double structural_source_pre_effective = std::max(structural_source_pre, kVacancyStructuralMin);
            v_t = build_vacancy_mass(v_legacy_pre, structural_source_pre_effective);
            u_t = cacu_2;

            double theta_raw = theta_ut;
            if (u_t > 1e-10 && std::isfinite(u_t)) {
                const double vacancy_to_unemp = std::max(v_t, 0.0) / u_t;
                theta_raw = bar_m * pow(vacancy_to_unemp, 1 - mu);
            }
            if (env_single_case == 51) {
                theta_raw = std::max(theta_raw, kMinThetaModel51);
            }
            theta_ut_new = clamp_probability(theta_raw);

            double rho_raw = rho_aver;
            if (cacu_1 > 1e-10) {
                rho_raw = ave_rho / cacu_1;
            }
            rho_aver_new = clamp_probability(rho_raw);


            //ave_work_prob = (cacu_2 * theta_ut_new + cacu_1 * (1 - ave_rho)) / (cacu_2 + cacu_1);//the real worker's prob
            //cout << "ave work prob: " << ave_work_prob << "  " << theta_ut_new << "  " << ave_rho << "  " << cacu_1_rho << "  " << u_t << "  " << cacu_0 << "  " << cacu_2 << endl;
        }



        for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
            ppl_edu = education_index_from_person(ppl_sim);
            //ave_rho = edu_rho[ppl_edu];//new rho
            // dim education dependent x_share(alpha and gamma)

            alpha = alpha_edu[ppl_edu];
            gamma_param = gamma_edu[ppl_edu];

            if (t_sim == 0) {
                //current asset:
                a0_sim[ppl_sim] = (a_l + a_h) / 4.0;
                //inherit previous m status, determine the current m.
                //x
                tmp_x_rnd = rnd_x_shk[t_sim][ppl_sim];
                x0_sim[ppl_sim] = x0_rnd_intial(tmp_x_rnd, ppl_edu);
                //cout << "ppl sim x_0" << x0_sim[ppl_sim] << endl;
            }

            else if (t_sim > 0) {

                //current asset:
                const double a0_candidate = a1_sim[ppl_sim];
                if (!std::isfinite(a0_candidate) || a0_candidate < a_l || a0_candidate > a_h) {
                    a0_out_of_grid_count += 1;
                }
                a0_sim[ppl_sim] = a0_candidate;
                //inherit previous shock status, determine the current one.
                //x
                tmp_x_rnd = rnd_x_shk[t_sim][ppl_sim];
                i_x_prev = x0_sim[ppl_sim];
                x0_sim[ppl_sim] = x0_rnd(tmp_x_rnd, i_x_prev, ppl_edu);
                //cout << "ppl sim x_0" << x0_sim[ppl_sim] << endl;
            }
            //current ability:
            //x0_sim[ppl_sim] = rnd_x_shk[t_sim][ppl_sim];



            //current period state: {a, x, occp, i_occp}:
            a0_sim_tmp = a0_sim[ppl_sim];
            x0_sim_tmp = x0_sim[ppl_sim];
            occp0_sim_tmp = occp0_sim[ppl_sim];

            // ---------------------------------------------------------
            // FIX 2: Correct Probabilistic Occupational Choice
            // ---------------------------------------------------------
            // Get the actual probability from interpolation instead of the binary 0/1 from intp_occp_sim
            double prob_work = intp_2d_opt(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu, opt_occp_0);
            
            // Generate a random number [0,1]
            double rnd_choice = ((double)rand()) / RAND_MAX;

            // Decide occupational choice based on probability
            if (rnd_choice <= prob_work) {
                i_occp0_sim_tmp = 1; // Worker
            } else {
                i_occp0_sim_tmp = 0; // Entrepreneur
            }
            // ---------------------------------------------------------

            //cout << "3" << endl;
            entr_ratio += 1.0 - i_occp0_sim_tmp;

            //labor demand:
            if (i_occp0_sim_tmp == 1) {
                n0_sim_tmp = 1.0;
                k0_sim_tmp = 0.0;
                y_sim[ppl_sim] = 0.0;
                agg_y_sim += y_sim[ppl_sim];

                //Z_agg with prob to supply labor next time.
                // it is same if i rewrite it after random check and relocated
                if (occp0_sim_tmp == 2.0 || occp0_sim_tmp == 0.0) {
                    z_agg += (1 + edu_z[ppl_edu]) * theta_ut_new;//if from umep to work
                }
                else if (occp0_sim[ppl_sim] == 1.0) {
                    z_agg += (1 + edu_z[ppl_edu]) * (1 - edu_rho[ppl_edu]);//if still work
                }
                

                //cout << "4" << endl;
            }
            else if (i_occp0_sim_tmp == 0) {
                //change for edu dim
                const double n0_raw = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_n_0);
                const double k0_raw = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_k_0);

                if (std::isfinite(n0_raw)) {
                    n_raw_min = std::min(n_raw_min, n0_raw);
                    n_raw_max = std::max(n_raw_max, n0_raw);
                    if (n0_raw < 0.0) { n_raw_negative_count += 1; }
                }
                if (std::isfinite(k0_raw)) {
                    k_raw_min = std::min(k_raw_min, k0_raw);
                    k_raw_max = std::max(k_raw_max, k0_raw);
                    if (k0_raw < 0.0) { k_raw_negative_count += 1; }
                }

                n0_sim_tmp = std::max(0.0, n0_raw);
                k0_sim_tmp = std::max(0.0, k0_raw);

                entr_count += 1;
                entr_count_edu[ppl_edu] += 1;
                n_entr_sum += n0_sim_tmp;
                k_entr_sum += k0_sim_tmp;
                n_entr_max = std::max(n_entr_max, n0_sim_tmp);
                k_entr_max = std::max(k_entr_max, k0_sim_tmp);
                if (n0_sim_tmp > 10.0) { n_tail_gt_10 += 1; }
                if (n0_sim_tmp > 100.0) { n_tail_gt_100 += 1; }
                if (n0_sim_tmp > 1000.0) { n_tail_gt_1000 += 1; }

                // ---------------------------------------------------------
                // FIX 1: Correct Output Calculation (removed i_occp0_sim_tmp *)
                // ---------------------------------------------------------
                y_sim[ppl_sim] = x0_sim_tmp * pow(k0_sim_tmp, alpha) * pow(n0_sim_tmp, gamma_param);
                // ---------------------------------------------------------

                agg_y_sim += y_sim[ppl_sim];

                //cout << "5" << endl;
            }

            n_sim[ppl_sim] = n0_sim_tmp;
            k0_sim[ppl_sim] = k0_sim_tmp;

            //EHI availability:

            a1_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_a_0);
            c0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_c_0);
            //change for edu dim
            rev_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_rev_0);
            //cout << "6" << endl;
            //tracking one agent
            //change for no health

            if (ppl_sim == 1005) {
                hhd_history[t_sim][0] = a0_sim_tmp;
                hhd_history[t_sim][1] = x0_sim_tmp;

                hhd_history[t_sim][5] = a1_sim_tmp;
                hhd_history[t_sim][6] = n0_sim_tmp;
                hhd_history[t_sim][7] = c0_sim_tmp;
                hhd_history[t_sim][8] = i_occp0_sim_tmp;
            }

            //income:
            double w0_tmp, pi_subsidy_tmp;
            w0_tmp = w0;


            //decisions:
            if (!std::isfinite(a1_sim_tmp) || a1_sim_tmp < a_l || a1_sim_tmp > a_h) {
                a1_out_of_grid_count += 1;
            }
            a1_sim[ppl_sim] = a1_sim_tmp;
            i_occp0_sim[ppl_sim] = i_occp0_sim_tmp;

            //desisions for real occp and prob
            if (i_occp0_sim_tmp == 0) {// to be an en
                occp0_sim[ppl_sim] = 0;
            }
            else {// to be a worker
                if (occp0_sim_tmp == 0 || occp0_sim_tmp == 2) {// unemploy
                    random_num = ((double)rand()) / RAND_MAX;
                    //cout << random_num << endl;
                    const double prob_find_job = clamp_probability(theta_ut_new);
                    if (random_num <= prob_find_job) {
                        occp0_sim[ppl_sim] = 1;
                        cacu_unemp += 1;
                    }
                    else {
                        occp0_sim[ppl_sim] = 2;//unep
                    }
                    cacu_tot_unemp += 1;

                }
                else if (occp0_sim_tmp == 1) {// employ
                    random_num = ((double)rand()) / RAND_MAX;
                    
                    const double prob_separation = clamp_probability(edu_rho[ppl_edu]);
                    if (random_num <= prob_separation) {
                        occp0_sim[ppl_sim] = 2;//unep
                    }
                    else{
                        occp0_sim[ppl_sim] = 1;
                        cacu_emp += 1;
                    }
                    cacu_tot_emp +=  1;
                }
            }

            //calculate aggregate variables
            occp0_sim_tmp = occp0_sim[ppl_sim];

            if (occp0_sim_tmp == 2) {//unemploy
                //n_supply +=  ;
            }
            else if (occp0_sim_tmp == 1) {//employ
                n_supply += (1 + edu_z[ppl_edu]);
            }
            else {
                n_demand += n0_sim_tmp;
            }


            if (n0_sim_tmp >= 100.0) {
                firm_big += 1.0;
            }

            //cacu income and tax
            if (i_occp0_sim_tmp == 1) {
                
                //if have a work pay tax and with aver_work_prob to have a work

                if (occp0_sim_tmp == 2 || occp0_sim_tmp == 0.0) {//unemploy
                    income_sim = (r0)*a0_sim_tmp + lowerincome_b * w0_tmp;
                    total_lower_out += lowerincome_b * w0_tmp;
                    tax_income = 0.0;
                }
                else if (occp0_sim_tmp == 1) {//employ
                    income_sim = (r0)*a0_sim_tmp + (1 + edu_z[ppl_edu]) * w0_tmp;// new cacu income with tax
                    tax_income = ((1 + edu_z[ppl_edu]) * w0_tmp * ((1 - psi) * tau_y0));

                    earning_wkr += income_sim;//real workers income
                }

            }
            else if (i_occp0_sim_tmp == 0) {//en
                income_sim = (r0)*a0_sim_tmp + rev_sim_tmp;
                tax_income = tau_pi;
                earning_entr += income_sim;
            }
            //total income:
            agg_income += income_sim;

            //total tax
            total_tax += tax_income;

            //calculate govrement pay for consumption
            c_gov_payment += intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, c_gov_pay);

            earning_sim += income_sim;
            asset_demand += k0_sim_tmp;
            asset_supply += a0_sim_tmp;

        }
    }
    if (!std::isfinite(n_raw_min)) { n_raw_min = 0.0; }
    if (!std::isfinite(n_raw_max)) { n_raw_max = 0.0; }
    if (!std::isfinite(k_raw_min)) { k_raw_min = 0.0; }
    if (!std::isfinite(k_raw_max)) { k_raw_max = 0.0; }
    const double entr_share_sim = static_cast<double>(entr_count) / static_cast<double>(Nsim_ppl);
    const double n_entr_avg = (entr_count > 0) ? (n_entr_sum / static_cast<double>(entr_count)) : 0.0;
    const double k_entr_avg = (entr_count > 0) ? (k_entr_sum / static_cast<double>(entr_count)) : 0.0;
    cout << "" << endl;
    cout << "***************entrepreneur realization diagnostics**************************" << endl;
    cout << "entr_count: " << entr_count << "  entr_share: " << entr_share_sim
        << "  entr_count_edu: [" << entr_count_edu[0] << ", " << entr_count_edu[1] << ", " << entr_count_edu[2] << "]" << endl;
    cout << "asset out-of-grid counts (a0_from_prev, a1_policy): " << a0_out_of_grid_count
        << ", " << a1_out_of_grid_count << endl;
    cout << "n_raw min/max: " << n_raw_min << " / " << n_raw_max
        << "  negative_raw_n_count: " << n_raw_negative_count << endl;
    cout << "k_raw min/max: " << k_raw_min << " / " << k_raw_max
        << "  negative_raw_k_count: " << k_raw_negative_count << endl;
    cout << "n_entrepreneur avg/max: " << n_entr_avg << " / " << n_entr_max
        << "  tail counts (>10, >100, >1000): " << n_tail_gt_10 << ", " << n_tail_gt_100 << ", " << n_tail_gt_1000 << endl;
    cout << "k_entrepreneur avg/max: " << k_entr_avg << " / " << k_entr_max << endl;
    cout << "" << endl;
    cout << "***************test prob and real prob**************************" << endl;
    cout << "in rand unemp prob: " << cacu_unemp / (cacu_tot_unemp + 1.0) << "  with real prob:" << theta_ut_new << endl;
    cout << "in rand emp prob: " << cacu_emp / (cacu_tot_emp + 1.0) << "  with real prob:" << 1.0 - rho_aver_new << endl;
    //cacu new theta_ut_new
    ave_rho = 0.0;
    cacu_1_rho = 0.0;
    cacu_0 = 0.0;
    cacu_1 = 0.0;
    cacu_2 = 0.0;
    double cacu_0_by_edu[Ne] = { 0.0, 0.0, 0.0 };
    double cacu_1_by_edu[Ne] = { 0.0, 0.0, 0.0 };
    double cacu_2_by_edu[Ne] = { 0.0, 0.0, 0.0 };
    double cacu_1rho_by_edu[Ne] = { 0.0, 0.0, 0.0 };

    for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
        ppl_edu = education_index_from_person(ppl_sim);
        a0_sim_tmp = a0_sim[ppl_sim];
        x0_sim_tmp = x0_sim[ppl_sim];
        occp0_sim_tmp = occp0_sim[ppl_sim];
        const double prob_work = clamp_probability(intp_2d_opt(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu, opt_occp_0));
        const double prob_entrepreneur = 1.0 - prob_work;
        cacu_0 += prob_entrepreneur;
        cacu_0_by_edu[ppl_edu] += prob_entrepreneur;
        if (occp0_sim[ppl_sim] == 2 || occp0_sim[ppl_sim] == 0) {
            cacu_2 += prob_work;
            cacu_2_by_edu[ppl_edu] += prob_work;
        }
        else if (occp0_sim[ppl_sim] == 1) {
            const double weighted_rho = prob_work * edu_rho[ppl_edu];
            cacu_1 += prob_work;
            cacu_1_rho += weighted_rho;
            ave_rho += weighted_rho;
            cacu_1_by_edu[ppl_edu] += prob_work;
            cacu_1rho_by_edu[ppl_edu] += weighted_rho;
        }
    }
    const double v_legacy_post = cacu_1_rho;
    const double structural_source_post = std::max(0.0, n_demand);
    const double structural_source_post_effective = std::max(structural_source_post, kVacancyStructuralMin);
    const double v_struct_post = std::max(0.0, env_vacancy_scale) * structural_source_post_effective;
    const double v_floor_post = std::max(0.0, env_vacancy_floor);
    v_t = build_vacancy_mass(v_legacy_post, structural_source_post);
    u_t = cacu_2;

    double theta_raw = theta_ut_new;
    if (u_t > 1e-10 && std::isfinite(u_t)) {
        const double vacancy_to_unemp = std::max(v_t, 0.0) / u_t;
        theta_raw = bar_m * pow(vacancy_to_unemp, 1 - mu);
    }
    if (env_single_case == 51) {
        theta_raw = std::max(theta_raw, kMinThetaModel51);
    }
    theta_ut_new = clamp_probability(theta_raw);

    double rho_raw = rho_aver_new;
    if (cacu_1 > 1e-10) {
        rho_raw = ave_rho / cacu_1;
    }
    else {
        rho_raw = rho_aver;
    }
    rho_aver_new = clamp_probability(rho_raw);
    const double vacancy_mode_component = std::max({
        v_legacy_post,
        (env_vacancy_mode >= 1) ? v_floor_post : 0.0,
        (env_vacancy_mode >= 2) ? v_struct_post : 0.0
    });
    cout << "[THETA_DIAG] v_t=" << v_t
        << " u_t=" << u_t
        << " v_legacy=" << v_legacy_post
        << " v_struct=" << v_struct_post
        << " v_floor=" << v_floor_post
        << " v_mode=" << env_vacancy_mode
        << " v_scale=" << env_vacancy_scale
        << " v_floor_param=" << env_vacancy_floor
        << " v_mode_comp=" << vacancy_mode_component
        << " c0=" << cacu_0
        << " c1=" << cacu_1
        << " c2=" << cacu_2
        << " v_struct_source=" << structural_source_post_effective
        << " theta_old=" << theta_ut
        << " theta_new=" << theta_ut_new
        << " rho_new=" << rho_aver_new
        << " c0_edu=[" << cacu_0_by_edu[0] << "," << cacu_0_by_edu[1] << "," << cacu_0_by_edu[2] << "]"
        << " c1_edu=[" << cacu_1_by_edu[0] << "," << cacu_1_by_edu[1] << "," << cacu_1_by_edu[2] << "]"
        << " c2_edu=[" << cacu_2_by_edu[0] << "," << cacu_2_by_edu[1] << "," << cacu_2_by_edu[2] << "]"
        << " v_edu=[" << cacu_1rho_by_edu[0] << "," << cacu_1rho_by_edu[1] << "," << cacu_1rho_by_edu[2] << "]" << endl;


    //cacu unemployment rate for how many nowadays people will unemp in next day with diff edu
    double unemp_edu_0_0, unemp_edu_1_0, unemp_edu_0_1,unemp_edu_1_1, unemp_edu_0_2, unemp_edu_1_2;
    double entr_edu_0_0, entr_edu_1_0, entr_edu_0_1, entr_edu_1_1, entr_edu_0_2, entr_edu_1_2;;
    double emp_edu_0_0, emp_edu_1_0, emp_edu_0_1, emp_edu_1_1, emp_edu_0_2, emp_edu_1_2;;

    int change_entr_count_edu_0, change_entr_count_edu_1, change_entr_count_edu_2;
    int change_work_count_edu_0, change_work_count_edu_1, change_work_count_edu_2;
    
    unemp_edu_0_0 = 0.0;
    unemp_edu_1_0 = 0.0;
    unemp_edu_0_1 = 0.0;
    unemp_edu_1_1 = 0.0;
    unemp_edu_0_2 = 0.0;
    unemp_edu_1_2 = 0.0;

    entr_edu_0_0 = 0.0;
    entr_edu_1_0 = 0.0;
    entr_edu_0_1 = 0.0;
    entr_edu_1_1 = 0.0;
    entr_edu_0_2 = 0.0;
    entr_edu_1_2 = 0.0;

    emp_edu_0_0 = 0.0;
    emp_edu_1_0 = 0.0;
    emp_edu_0_1 = 0.0;
    emp_edu_1_1 = 0.0;
    emp_edu_0_2 = 0.0;
    emp_edu_1_2 = 0.0;

    change_entr_count_edu_0 = 0;
    change_entr_count_edu_1 = 0;
    change_entr_count_edu_2 = 0;

    change_work_count_edu_0 = 0;
    change_work_count_edu_1 = 0;
    change_work_count_edu_2 = 0;


    for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

        a0_sim_tmp = a0_sim[ppl_sim];// individual's asset
        x0_sim_tmp = x0_sim[ppl_sim];// x
        occp0_sim_tmp = occp0_sim[ppl_sim];// now location
        ppl_edu = education_index_from_person(ppl_sim);
        const double prob_work = clamp_probability(intp_2d_opt(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu, opt_occp_0));
        const double prob_entrepreneur = 1.0 - prob_work;
        const double edu_mass_denom = Nsim_ppl * edu_share[ppl_edu];
        if (edu_mass_denom <= 0.0) {
            continue;
        }

        const double choose_entr_mass = prob_entrepreneur / edu_mass_denom;
        const double choose_work_mass = prob_work / edu_mass_denom;

        if (ppl_edu == 0) {
            if (occp0_sim_tmp == 0) {
                entr_edu_0_0 += choose_entr_mass;
                entr_edu_1_0 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 1) {
                emp_edu_0_0 += choose_entr_mass;
                emp_edu_1_0 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 2) {
                unemp_edu_0_0 += choose_entr_mass;
                unemp_edu_1_0 += choose_work_mass;
            }
        }
        else if (ppl_edu == 1) {
            if (occp0_sim_tmp == 0) {
                entr_edu_0_1 += choose_entr_mass;
                entr_edu_1_1 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 1) {
                emp_edu_0_1 += choose_entr_mass;
                emp_edu_1_1 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 2) {
                unemp_edu_0_1 += choose_entr_mass;
                unemp_edu_1_1 += choose_work_mass;
            }
        }
        else {
            if (occp0_sim_tmp == 0) {
                entr_edu_0_2 += choose_entr_mass;
                entr_edu_1_2 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 1) {
                emp_edu_0_2 += choose_entr_mass;
                emp_edu_1_2 += choose_work_mass;
            }
            else if (occp0_sim_tmp == 2) {
                unemp_edu_0_2 += choose_entr_mass;
                unemp_edu_1_2 += choose_work_mass;
            }
        }

    }

    cout << "" << endl;
    cout << "***************unemployment rate in different edu**************************" << endl;
    cout << "edu level 0:   the unemp rate:" << unemp_edu_1_0 << "  the entr rate: " << entr_edu_1_0 << "  the working rate: " << emp_edu_1_0 << endl;
    cout << "edu level 1:   the unemp rate:" << unemp_edu_1_1 << "  the entr rate: " << entr_edu_1_1 << "  the working rate: " << emp_edu_1_1 << endl;
    cout << "edu level 2:   the unemp rate:" << unemp_edu_1_2 << "  the entr rate: " << entr_edu_1_2 << "  the working rate: " << emp_edu_1_2 << endl;


    double tmp_a0, tmp_x0, tmp_cev;
    double tmp_a, tmp_x;
    int tmp_z0, tmp_m0, tmp_i_HI0;
    //changed line
    ofstream file_2(workingpath_new + "sim_v18.txt");
    ave_welfare = 0.0;
    for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

        tmp_a0 = a0_sim[ppl_sim];
        tmp_x0 = x0_sim[ppl_sim];
        occp0_sim_tmp = occp0_sim[ppl_sim];
        ppl_edu = education_index_from_person(ppl_sim);

        tmp_cev = intp_2d_opt(tmp_a0, tmp_x0, occp0_sim_tmp, ppl_edu, cev);
        cev_sim[ppl_sim] = tmp_cev;

        ave_welfare += tmp_cev;

        file_2 << a0_sim[ppl_sim] << " " << x0_sim[ppl_sim] << " "
            << a1_sim[ppl_sim] << " " << i_occp0_sim[ppl_sim] << " " << n_sim[ppl_sim] << " " << k0_sim[ppl_sim] << " " << y_sim[ppl_sim] << " "
            << cev_sim[ppl_sim] << endl;
    }
    file_2.close();


    //calculate aggregate variables.
    const double asset_gap = safe_market_gap(asset_demand, asset_supply);
    const double labor_gap = safe_market_gap(n_demand, n_supply);

    const double r1_candidate = (1.0 - r_decompose) * (1.0 + asset_gap) * r0 + r_decompose * r_ben;
    const double w1_candidate = (1.0 + labor_gap) * w0;

    r1 = safe_positive_update(r1_candidate, r0, 0.001);
    w1 = safe_positive_update(w1_candidate, w0, 1e-6);
    //cout << "7.5" << endl;

    ave_earning1 = earning_sim / Nsim_ppl;

    const double govt_outlays = total_lower_out + c_gov_payment;
    if (fabs(earning_wkr) > 1e-10 && std::isfinite(earning_wkr)) {
        tau_y1 = govt_outlays / earning_wkr;// cacu need out num
    }
    else {
        tau_y1 = tau_y0;
    }
    if (!std::isfinite(tau_y1) || tau_y1 < 0.0) {
        tau_y1 = tau_y0;
    }

    t_lumpsum1 = govt_outlays / Nsim_ppl;
    if (!std::isfinite(t_lumpsum1)) {
        t_lumpsum1 = t_lumpsum0;
    }

    if (ind_policy == 0) {
        t_lumpsum_ben = t_lumpsum1 / ave_earning1;
    }

    if (dummy_UI == 1) {
        t_lumpsum1 = t_lumpsum_ben * ave_earning1;
    }

    agg_cfloor_transfer = agg_cfloor_transfer / Nsim_ppl;
    n_cfloor_transfer = n_cfloor_transfer / Nsim_ppl;

    if (fabs(agg_y_sim) > 1e-10 && std::isfinite(agg_y_sim)) {
        a_y = asset_supply / agg_y_sim;
        k_y = asset_demand / agg_y_sim;
    }
    else {
        a_y = 0.0;
        k_y = 0.0;
    }

    //health insurance
    if (fabs(n_supply) > 1e-10 && std::isfinite(n_supply)) {
        earning_wkr = earning_wkr / n_supply;
    }
    else {
        earning_wkr = 0.0;
    }
    if (fabs(entr_ratio) > 1e-10 && std::isfinite(entr_ratio)) {
        earning_entr = earning_entr / entr_ratio;
    }
    else {
        earning_entr = 0.0;
    }



    //firm dist.
    if (fabs(entr_ratio) > 1e-10 && std::isfinite(entr_ratio)) {
        firm_size = n_demand / entr_ratio;
        firm_big = firm_big / entr_ratio;
    }
    else {
        firm_size = 0.0;
        firm_big = 0.0;
    }

    entr_ratio = entr_ratio / Nsim_ppl;

    gdp1 = agg_y_sim;
    ave_welfare = ave_welfare / Nsim_ppl;

    if (fabs(n_supply) > 1e-10 && std::isfinite(n_supply)) {
        z_agg = z_agg / n_supply;
    }
    else {
        z_agg = 0.0;
    }

    // Calculate current government budget
    double current_total_tax = total_tax;
    double current_UI_spending = total_lower_out;
    double current_cfloor_spending = c_gov_payment;
    double current_govt_spending = current_UI_spending + current_cfloor_spending;
    
    // NEW: Calculate lump-sum tax/transfer for fixed tax experiments
    if (use_fixed_tax_rate) {
        
        // Current government budget with FIXED tax rate
        // Revenue: current_total_tax (from fixed tau_y_baseline applied to current tax base)
        // Spending: current_govt_spending (UI + consumption floor transfers)
        
        // Budget gap that needs to be filled by lump-sum
        double budget_gap = current_govt_spending - current_total_tax;
        
        if (use_deadweight_loss) {
            // DWL EXPERIMENT LOGIC:
            // We collect tax at HIGHER rate tau_y0 = tau_y_baseline * multiplier
            // But the "extra" revenue beyond baseline is pure waste (thrown away)
            // So effective revenue available = what we would have collected at baseline rate
            
            // Calculate what revenue would be at baseline rate
            // current_total_tax was collected at rate tau_y0
            // baseline revenue would be: current_total_tax * (tau_y_baseline / tau_y0)
            double baseline_equivalent_revenue = current_total_tax * (tau_y_baseline / tau_y0);
            
            // The difference is deadweight loss (wasted/thrown away)
            dwl_revenue = current_total_tax - baseline_equivalent_revenue;
            
            // Budget must balance using only baseline-equivalent revenue + lump-sum
            budget_gap = current_govt_spending - baseline_equivalent_revenue;
            
            // Lump-sum fills the gap
            t_lumpsum_endogenous = budget_gap / Nsim_ppl;
            
            // Keep the elevated tax rate
            tau_y1 = tau_y0;
            
            cout << "" << endl;
            cout << "***************DEADWEIGHT LOSS EXPERIMENT**************************" << endl;
            cout << "Baseline tax rate: " << tau_y_baseline << " (" << 100*tau_y_baseline << "%)" << endl;
            cout << "Elevated tax rate: " << tau_y0 << " (" << 100*tau_y0 << "%)" << endl;
            cout << "Tax rate increase: +" << 100*(tau_y_dwl_multiplier-1) << "%" << endl;
            cout << "" << endl;
            cout << "REVENUE:" << endl;
            cout << "  Total tax revenue collected (at elevated rate): " << current_total_tax << endl;
            cout << "  Baseline-equivalent revenue (at baseline rate): " << baseline_equivalent_revenue << endl;
            cout << "  DEADWEIGHT LOSS (thrown away): " << dwl_revenue << endl;
            cout << "    (as % of GDP): " << 100 * dwl_revenue / gdp1 << "%" << endl;
            cout << "" << endl;
            cout << "BUDGET:" << endl;
            cout << "  Government spending: " << current_govt_spending << endl;
            cout << "  Usable revenue (baseline equivalent): " << baseline_equivalent_revenue << endl;
            cout << "  Budget gap: " << budget_gap << endl;
            cout << "  Per-capita lump-sum to balance: " << t_lumpsum_endogenous << endl;
            cout << "" << endl;
            cout << "VERIFICATION:" << endl;
            double total_effective_revenue = baseline_equivalent_revenue + t_lumpsum_endogenous * Nsim_ppl;
            cout << "  Total effective revenue: " << total_effective_revenue << endl;
            cout << "  Budget balance check: " << total_effective_revenue - current_govt_spending << endl;
            cout << "    (should be ≈ 0)" << endl;
            cout << "================================================================" << endl;
            
        } else {
            // Per-capita lump-sum tax (positive) or transfer (negative)
            t_lumpsum_endogenous = budget_gap / Nsim_ppl;
            
            // Update tau_y1 for next iteration (keep it fixed)
            tau_y1 = tau_y_baseline;
        }
        
        cout << "" << endl;
        cout << "***************FIXED TAX BUDGET ANALYSIS**************************" << endl;
        cout << "Fixed tau_y (from baseline): " << tau_y_baseline << endl;
        cout << "" << endl;
        cout << "CURRENT PERIOD BUDGET:" << endl;
        cout << "  Revenue (from fixed tax):" << endl;
        cout << "    - Income tax revenue: " << current_total_tax << endl;
        cout << "    - Total tax revenue: " << current_total_tax << endl;
        cout << "  Spending:" << endl;
        cout << "    - UI payments: " << current_UI_spending << endl;
        cout << "    - Consumption floor transfers: " << current_cfloor_spending << endl;
        cout << "    - Total spending: " << current_govt_spending << endl;
        cout << "  Budget gap: " << budget_gap;
        if (budget_gap > 0) {
            cout << " (spending > revenue, need lump-sum TAX)" << endl;
        } else {
            cout << " (revenue > spending, give lump-sum TRANSFER)" << endl;
        }
        cout << "  Per-capita lump-sum: " << t_lumpsum_endogenous;
        if (t_lumpsum_endogenous > 0) {
            cout << " (POSITIVE = each household pays lump-sum TAX)" << endl;
        } else {
            cout << " (NEGATIVE = each household receives lump-sum TRANSFER)" << endl;
        }
        cout << "  Total lump-sum: " << t_lumpsum_endogenous * Nsim_ppl << endl;
        cout << "" << endl;
        
        // Verification
        double budget_check = current_total_tax + t_lumpsum_endogenous * Nsim_ppl - current_govt_spending;
        cout << "  Budget verification (should be ~0): " << budget_check << endl;
        
        // Compare with baseline if available
        if (i_case > 101 && baseline_total_tax > 0) {
            cout << "" << endl;
            cout << "COMPARISON WITH BASELINE (case 101):" << endl;
            cout << "  Change in tax revenue: " << current_total_tax - baseline_total_tax 
                 << " (" << 100*(current_total_tax - baseline_total_tax)/baseline_total_tax << "%)" << endl;
            cout << "  Change in UI spending: " << current_UI_spending - baseline_UI_spending
                 << " (" << 100*(current_UI_spending - baseline_UI_spending)/baseline_UI_spending << "%)" << endl;
            cout << "  Change in consumption floor spending: " << current_cfloor_spending - baseline_cfloor_spending
                 << " (" << 100*(current_cfloor_spending - baseline_cfloor_spending)/baseline_cfloor_spending << "%)" << endl;
            cout << "  Baseline had balanced budget (lump-sum = 0)" << endl;
            cout << "  Now need lump-sum of: " << t_lumpsum_endogenous << " per capita" << endl;
            cout << "" << endl;
            
            // Decomposition of why lump-sum is needed
            double revenue_effect = current_total_tax - baseline_total_tax;
            double UI_effect = current_UI_spending - baseline_UI_spending;
            double cfloor_effect = current_cfloor_spending - baseline_cfloor_spending;
            
            cout << "DECOMPOSITION OF LUMP-SUM NEED:" << endl;
            cout << "  Revenue change (negative = lost revenue): " << revenue_effect << endl;
            cout << "  UI spending change (positive = more spending): " << UI_effect << endl;
            cout << "  C-floor spending change (positive = more spending): " << cfloor_effect << endl;
            cout << "  Net lump-sum need: " << -revenue_effect + UI_effect + cfloor_effect << endl;
            cout << "    (should equal per-capita lump-sum * N = " << t_lumpsum_endogenous * Nsim_ppl << ")" << endl;
        }
        cout << "================================================================" << endl;
    }
    else {
        // In baseline mode, update tau_y endogenously
        // The new tau_y1 is calculated to balance the budget
        //tau_y1 = current_govt_spending / (ave_earning1 * (1 - psi));  // Approximate
        
        // If this is case 101, save baseline values
        if (i_case == 101) {
            baseline_total_tax = current_total_tax;
            baseline_UI_spending = current_UI_spending;
            baseline_cfloor_spending = current_cfloor_spending;
            baseline_govt_spending = current_govt_spending;
        }
    }
    
    cout << "" << endl;
    cout << "***************some simulation result**************************" << endl;
    cout << "sim ans nsup: " << n_supply <<"   ndemand: " << n_demand << "  " << z_agg << endl;
    cout << "sim next pi tau y  " << tau_y1 << "gov_pay consumption" << c_gov_payment << endl;
    cout << "sim ans tax part with tax: " << total_tax << "  with out lower income: " << total_lower_out << endl;


    float tol_check_cacu = abs(r0 - r1) + abs(w0 - w1) + abs(theta_ut - theta_ut_new) + abs(tau_y0 - tau_y1);
    if (tol_check_cacu < best_check_tol) {
        best_check_tol = tol_check_cacu;
        ofstream file_0(workingpath_new + "best_result.txt");
        file_0 << r0 << " " << r1 << " " << w0 << " " << w1 << " " << tau_y0 << " " << tau_y1 << " " << theta_ut<<" " << theta_ut_new << endl;
        file_0 << " " << unemp_edu_0_0 << " " << unemp_edu_1_0 << " " << entr_edu_0_0 << " " << entr_edu_1_0 << " " << emp_edu_0_0<< " " << emp_edu_1_0 << endl;
        file_0 << " " << unemp_edu_0_1 << " " << unemp_edu_1_1 << " " << entr_edu_0_1 << " " << entr_edu_1_1 << " " << emp_edu_0_1<< " " << emp_edu_1_1 << endl;
        file_0 << " " << unemp_edu_0_2 << " " << unemp_edu_1_2 << " " << entr_edu_0_2 << " " << entr_edu_1_2 << " " << emp_edu_0_2<< " " << emp_edu_1_2 << endl;
        file_0 << " " << n_supply << " " << n_demand << " " << z_agg << endl;
        file_0 << " " << total_tax << " " << total_lower_out << endl;
        file_0 << " " << c_gov_payment << endl;


        ofstream file(workingpath_new + "state_change_occp_insim.txt");
        ofstream file_1(workingpath_new + "opt_n_diff_edu.txt");
        for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

            a0_sim_tmp = a0_sim[ppl_sim];// individual's asset
            x0_sim_tmp = x0_sim[ppl_sim];// x
            occp0_sim_tmp = occp0_sim[ppl_sim];// now location
            ppl_edu = education_index_from_person(ppl_sim);
            i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);// use policy to cacu next loc: choose work or entr
            // now a /now x /now edu/ now state  /next choose
            file << a0_sim_tmp << " " << x0_sim_tmp << " " << ppl_edu << " " << occp0_sim_tmp << " " << i_occp0_sim_tmp << endl;

            if (i_occp0_sim_tmp == 0) {
                n0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_n_0);
                file_1 << ppl_edu << " " << n0_sim_tmp << endl;
            }


        }
        file.close();
        file_0.close();
        file_1.close();

    }

    // save state a, state x, state edu, now pos/ next choose to be a (worker, en)
    ofstream file_3(workingpath_new + "choose_state_next.txt");
    for (int i_e = 0; i_e < Ne; i_e++) {
        for (int i_a = 0; i_a < Na; i_a++) {
            for (int i_x = 0; i_x < Nx; i_x++) {
                for (int i_occp_0 = 0; i_occp_0 < Ni; i_occp_0++) {
                    tmp_a = a_vec[i_a];
                    tmp_x = x_shk[i_x][i_e];

                    i_occp0_sim_tmp = intp_occp_sim(tmp_a, tmp_x, i_occp_0, i_e);

                    file_3 << tmp_a << " " << tmp_x << " " << i_e << " " << i_occp_0 << " " << i_occp0_sim_tmp << endl;

                }
            }
        }
    }
    file_3.close();

    cout << "best_tol in model now" << best_check_tol << endl;

}

//change for no health
void assign_value()
{
	// Define baseline edu_rho to reset for each case
	double base_edu_rho[Ne] = { 0.0383, 0.0288, 0.0136 };

	//set grid points.
	a_l = 0.01;
	a_h = 200.0;

	x_l = 0.0;
	x_h = 1.0;

	x_scale = 1.0;
	x_eps = 4.422;
	tau_s = 0.12;

	dep_k = 0.04;

	//Markov chain for x, z, m:
	//change for no health
	m_scale = 1.50;
	pi_x_input();

	//cout << pi_x_inv[1][0] << pi_x_inv[1][1] << pi_x_inv[1][2] << endl;
	//change

	//pi_m_input();

	//grids for {a, x}
	double tmp_grid;
	for (int i_a = 0; i_a < Na; i_a++) {
		//uneven grid:
		tmp_grid = (log(a_h) - log(a_l)) / (Na - 1) * i_a + log(a_l);

		a_vec[i_a] = exp(tmp_grid);

		//cout << a_vec[i_a] << endl;
	}

	//****************
	//key parameters:
	//****************
	r_wedge = (1.0 - r_wedge_decompose) * 0.60 + r_wedge_decompose * r_wedge_exp;
	beta = 0.94;
	sigma = 2.0;
	dep_k = 0.06;
	//x_share = 0.80;
	k_share = 0.406;

	c_floor_adj = 1.0;
	c_floor = 9700 / real_gdp / c_floor_adj;

	rho_aver = 0.03;// average job market rho

	tau_pi = 0;
	psi = 0;

	kappa = 0.03; //with w

	mu = 0.6;
	bar_m = 1;
	lowerincome_b = 0.4;

	cout << "with model: " << i_case << endl;
	
	//case 101 is the baseline.
	//case 102, no UI
	//need figure out how Lump-sum transfer, penalty cases are modeled and coded.
	//underline_c: consumption floor; lowerincome_b: UI benefit; 
	//bar_m: Matching efficiency; mu: Matching elasticity

	//baseline
	cout << "with model: " << i_case << endl;
	
	///************************************************************************
	// FINAL EXPERIMENTAL DESIGN - CORRECTED
	//************************************************************************
	// 
	// **BASELINE**: Case 101
	// 
	// **PART A: ENDOGENOUS TAX** (cases 102-107)
	//  102: Low UI (endogenous tax)
	//  103: No UI (endogenous tax)
	//  104: Low consumption floor (endogenous tax)
	//  105: Low matching efficiency (endogenous tax)
	//  106: Low matching elasticity (endogenous tax)
	//  107: High search cost (endogenous tax)
	//
	// **PART B: FIXED TAX + LUMP-SUM** (cases 111-117)
	//  111: Baseline verification (fixed tax, should replicate 101)
	//  112: Low UI (fixed tax) - compare with 102
	//  113: No UI (fixed tax) - compare with 103
	//  114: Low consumption floor (fixed tax) - compare with 104
	//  115: Low matching efficiency (fixed tax) - compare with 105
	//  116: Low matching elasticity (fixed tax) - compare with 106
	//  117: High search cost (fixed tax) - compare with 107
	//
	// **PART C: CONSUMPTION PENALTY** (cases 120-121)
	//  120: Misaligned thresholds (penalty@0.3, transfer@0.1, endogenous tax)
	//  121: Misaligned thresholds (penalty@0.3, transfer@0.1, fixed tax)
	//
	// **PART D: DEADWEIGHT LOSS** (cases 130-131)
	//  130: +5% tax rate, extra revenue thrown away as DWL
	//  131: +10% tax rate, extra revenue thrown away as DWL
	
	// 11/10/2025
	// 1. increasing the all job separation rate edu_rho. + 10-15%
	//    baseline and the case with low UI.
	//    need to check "rho_aver" and its role;
	// 2. increasing the job separation rate for the low education group, + 10-15%. edu_rho
	//    baseline and the case with low UI.
	
	// check the results for cases 123 and 113, particularly the tax rates.
	//************************************************************************
	// Default: no deadweight loss
	use_deadweight_loss = false;
	tau_y_dwl_multiplier = 1.0;
	dwl_revenue = 0.0;
	
	// Default: no consumption penalty
	use_consumption_penalty = false;
	penalty_threshold = 0.0;
	penalty_weight = 0.0;
	
	// Default: no fixed tax
	use_fixed_tax_rate = false;
	//tau_y_baseline = 0.0;
	t_lumpsum_endogenous = 0.0;
	//========================================================================
	// BASELINE CASE
	//========================================================================
	
	// Case 110: BASELINE (reference case for all experiments)
	if (i_case == 101) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		// No penalty
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// Endogenous tax adjustment (standard case)
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;
		
		// Initialize baseline budget components (will be saved)
		baseline_total_tax = 0.0;
		baseline_UI_spending = 0.0;
		baseline_cfloor_spending = 0.0;
		baseline_govt_spending = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	//========================================================================
	// PART A: ENDOGENOUS TAX EXPERIMENTS
	// Tax rate adjusts to balance budget
	//========================================================================
	
	// Case 102: Low UI benefit (endogenous tax)
	if (i_case == 102) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.2;     // CHANGE: Lower UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 103: No UI benefit (endogenous tax)
	if (i_case == 103) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.05;    // CHANGE: Almost no UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 1031: high UI benefit (endogenous tax)
	if (i_case == 1031) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.8;    // CHANGE: Almost no UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;
	
		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 1032: high UI benefit (endogenous tax)
	if (i_case == 1032) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 1.0;    // CHANGE: Almost no UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;
	
		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 104: Low consumption floor (endogenous tax)
	if (i_case == 104) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.1;       // CHANGE: Lower floor
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 105: Low matching efficiency (endogenous tax)
	if (i_case == 105) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.5;             // CHANGE: Lower matching efficiency
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 106: Low matching elasticity (endogenous tax)
	if (i_case == 106) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.5;              // CHANGE: Lower matching elasticity
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 107: High search cost (endogenous tax)
	if (i_case == 107) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
	
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
	
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.06;            // CHANGE: Higher search cost
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	//========================================================================
	// PART B: FIXED TAX EXPERIMENTS
	// Tax rate fixed at baseline level, lump-sum balances budget
	// Compare with corresponding Part A cases to isolate tax distortion effects
	//========================================================================
	
	// Case 111: Baseline with fixed tax (verification case)
	// add this case for this block, as the running time limit requires computation block by block.
	// Should replicate case 101 with lump-sum ≈ 0
	if (i_case == 111) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		// No penalty
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// Endogenous tax adjustment (standard case)
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;
		
		// Initialize baseline budget components (will be saved)
		baseline_total_tax = 0.0;
		baseline_UI_spending = 0.0;
		baseline_cfloor_spending = 0.0;
		baseline_govt_spending = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 112: Low UI with fixed tax
	// Compare with case 102 (same policy, different tax system)
	if (i_case == 112) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.2;     // CHANGE: Lower UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax, expect lump-sum TRANSFER
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 113: No UI with fixed tax
	// Compare with case 103 (same policy, different tax system)
	if (i_case == 113) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.1;    // CHANGE: Almost no UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax, expect large lump-sum TRANSFER
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 114: Low consumption floor with fixed tax
	// Compare with case 104 (same policy, different tax system)
	if (i_case == 114) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.1;       // CHANGE: Lower floor
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax, expect lump-sum TRANSFER
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 115: Low matching efficiency with fixed tax
	// Compare with case 105 (same policy, different tax system)
	if (i_case == 115) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.5;             // CHANGE: Lower matching efficiency
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax, expect lump-sum TAX (more unemployment)
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 116: Low matching elasticity with fixed tax
	// Compare with case 106 (same policy, different tax system)
	if (i_case == 116) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.5;              // CHANGE: Lower matching elasticity
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 117: High search cost with fixed tax
	// Compare with case 107 (same policy, different tax system)
	if (i_case == 117) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.06;            // CHANGE: Higher search cost
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = true; // FIX tax
		t_lumpsum_endogenous = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	//========================================================================
	// PART C: CONSUMPTION PENALTY EXPERIMENTS
	// Alternative mechanism: penalty in utility function instead of transfers
	//========================================================================
	
	// Case 121: Baseline with fixed tax (verification case)
	// add this case for this block, as the running time limit requires computation block by block
	// Should replicate case 101 with lump-sum ≈ 0
	if (i_case == 121) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		// No penalty
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// Endogenous tax adjustment (standard case)
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;
		
		// Initialize baseline budget components (will be saved)
		baseline_total_tax = 0.0;
		baseline_UI_spending = 0.0;
		baseline_cfloor_spending = 0.0;
		baseline_govt_spending = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 122: Penalty with low transfer floor (misaligned thresholds, endogenous tax)
	// Penalty kicks in at c=0.3, but government only transfers when c<0.1
	// Tax adjusts endogenously to finance transfers
	if (i_case == 122) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.1;       // CHANGE: Low transfer floor (0.1)
		
		use_consumption_penalty = true;
		penalty_threshold = 0.3; // CHANGE: Penalty kicks in higher (0.3)
		penalty_weight = 500.0;
		
		use_fixed_tax_rate = false; // Tax adjusts endogenously

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 123: Penalty with low transfer floor (misaligned thresholds, fixed tax + lump-sum)
	// Same as case 122, but with fixed tax and lump-sum adjustment
	// Isolates pure penalty effect without tax distortion changes
	if (i_case == 123) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.1;       // CHANGE: Low transfer floor (0.1)
		
		use_consumption_penalty = true;
		penalty_threshold = 0.3; // CHANGE: Penalty kicks in higher (0.3)
		penalty_weight = 500.0;
		
		use_fixed_tax_rate = true;   // FIX tax at baseline level
		t_lumpsum_endogenous = 0.0; // Lump-sum balances budget

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	
	//========================================================================
	// PART D: DEADWEIGHT LOSS EXPERIMENTS
	// Artificially increase tax rate, revenue thrown away as pure DWL
	//========================================================================
	
	// Case 131: Baseline with fixed tax (verification case)
	// add this case for this block, as the running time limit requires computation block by block.
	// Should replicate case 101 with lump-sum ≈ 0
	if (i_case == 131) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		// No penalty
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// Endogenous tax adjustment (standard case)
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;
		
		// Initialize baseline budget components (will be saved)
		baseline_total_tax = 0.0;
		baseline_UI_spending = 0.0;
		baseline_cfloor_spending = 0.0;
		baseline_govt_spending = 0.0;

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 132: 5% higher tax rate (pure deadweight loss)
	if (i_case == 132) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// CHANGE: Fix tax at 5% higher than baseline
		use_fixed_tax_rate = true;
		// tau_y_baseline will be set from case 101, then increased
		t_lumpsum_endogenous = 0.0;
		
		// Mark this as DWL experiment
		use_deadweight_loss = true;
		tau_y_dwl_multiplier = 1.05; // 5% increase

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}
	
	// Case 133: 10% higher tax rate (pure deadweight loss)
	if (i_case == 133) {
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		// CHANGE: Fix tax at 10% higher than baseline
		use_fixed_tax_rate = true;
		t_lumpsum_endogenous = 0.0;
		
		// Mark this as DWL experiment
		use_deadweight_loss = true;
		tau_y_dwl_multiplier = 1.10; // 10% increase

		// *** MODIFICATION: Reset edu_rho to baseline ***
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
	}

	// =======================================================================
	// NEW EXPERIMENTS (TASKS 2 & 3)
	// =======================================================================

	// Case 134: Baseline (101) + High ALL separation rate (+0.1)
	if (i_case == 134) {
		// Copy all parameters from case 101
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;
		
		// Set edu_rho from baseline
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
		
		// CHANGE: Increase all separation rates
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] += 0.1; 
		}
	}

	// Case 135: Low UI (102) + High ALL separation rate (+0.1)
	if (i_case == 135) {
		// Copy all parameters from case 102
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.2;  // Low UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// Set edu_rho from baseline
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
		
		// CHANGE: Increase all separation rates
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] += 0.1; 
		}
	}

	// Case 136: Baseline (101) + High LOW-EDU separation rate (+0.1)
	if (i_case == 136) {
		// Copy all parameters from case 101
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.4;
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		penalty_threshold = 0.0;
		penalty_weight = 0.0;
		
		use_fixed_tax_rate = false;
		tau_y_baseline = 0.0;
		t_lumpsum_endogenous = 0.0;

		// Set edu_rho from baseline
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
		
		// CHANGE: Increase only low-edu (index 0) separation rate
		edu_rho[0] += 0.1; 
	}

	// Case 137: Low UI (102) + High LOW-EDU separation rate (+0.1)
	if (i_case == 137) {
		// Copy all parameters from case 102
		beta = 0.94;
		double x_share_dims[3] = { 0.782, 0.802, 0.822 };
		for (int i_loop = 0; i_loop < 3; i_loop++) {
			x_share_edu[i_loop] = x_share_dims[i_loop];
		}
		bar_m = 0.9;
		mu = 0.68;
		kappa = 0.035;
		lowerincome_b = 0.2;  // Low UI
		underline_c = 0.3;
		
		use_consumption_penalty = false;
		use_fixed_tax_rate = false;

		// Set edu_rho from baseline
		for (int i_rho = 0; i_rho < Ne; i_rho++) {
			edu_rho[i_rho] = base_edu_rho[i_rho];
		}
		
		// CHANGE: Increase only low-edu (index 0) separation rate
		edu_rho[0] += 0.1; 
	}
	
	// //////////////////

	//=====================================================
	// Homotopy override hooks
	//=====================================================
	if (override_lowerincome_b) {
		lowerincome_b = lowerincome_b_override;
		cout << "[override] lowerincome_b = " << lowerincome_b << endl;
	}

	for (int i_loop = 0; i_loop < 3; i_loop++) {
		alpha_edu[i_loop] = k_share * x_share_edu[i_loop];
		gamma_edu[i_loop] = (1.0 - k_share) * x_share_edu[i_loop];
		cout << " alpha_i " << alpha_edu[i_loop] << " gamma_i " << gamma_edu[i_loop] << endl;
	}


	cout << "assign_value" << endl;
}

//change for new
void initialize_value()
{
	//initialize policy and value functions:
	//change for edu
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp_1 = 0; i_occp_1 < Ni; i_occp_1++) {
					v1[i_a][i_x][i_occp_1][i_e] = 0.0;
					//change for new
					for (int i_occp = 0; i_occp < Ni; i_occp++) {
						for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
							opt_a_1[i_occp][i_occp_e][i_a][i_x][i_e] = beta * a_vec[i_a] + 0.5;
							opt_k_1[i_occp][i_occp_e][i_a][i_x][i_e] = a_vec[i_a];
							opt_n_1[i_occp][i_occp_e][i_a][i_x][i_e] = 1.0;
						}
					}
				}
			}
		}
	}

	policy_input();

	//change for edu dim
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp_1 = 0; i_occp_1 < Ni; i_occp_1++) {
					v1[i_a][i_x][i_occp_1][i_e] = 0.0;
					//change for new
					for (int i_occp = 0; i_occp < Ni; i_occp++) {
						for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
							opt_a_1[i_occp][i_occp_e][i_a][i_x][i_e] = beta * a_vec[i_a] + 0.5;
							opt_k_1[i_occp][i_occp_e][i_a][i_x][i_e] = a_vec[i_a];
							opt_n_1[i_occp][i_occp_e][i_a][i_x][i_e] = 1.0;
						}
					}
				}
			}
		}
	}

	gen_rnd();

	comp_accum_x();

	//initalize agg. variables:

	gdp0 = 0.0;
	r0 = 0.083266 + 0.005;
	w0 = 0.790679;
	tfp = 1.0;
	c_EHI0 = 0.0680308;
	insure_rate = 0.7723;

	ave_earning0 = 1.53522;
	t_lumpsum0 = 0.0330912;
	tau_y0 = 0.04;
	/// NEW: Initialize for fixed tax experiments
	if (use_fixed_tax_rate) {
		if (tau_y_baseline > 0) {
			// For DWL experiments, increase tax rate
			if (use_deadweight_loss) {
				tau_y0 = tau_y_baseline * tau_y_dwl_multiplier;
			} else {
				tau_y0 = tau_y_baseline;  // Use baseline for regular fixed-tax cases
			}
		} else {
			cout << "WARNING: tau_y_baseline not set yet. Run case 101 first!" << endl;
			tau_y0 = 0.0382;
		}
		t_lumpsum_endogenous = 0.0;
	}
	z_agg = 1.00331;
	theta_ut = 0.3;
	theta_ut_new = theta_ut;

	r1 = r0;
	w1 = w0;
	c_EHI1 = c_EHI0;
	tau_y1 = tau_y0;
	gdp1 = gdp0;
	ave_earning1 = ave_earning0;
	t_lumpsum1 = t_lumpsum0;

	govt = 0.2;
	cout << "initialize_value " << endl;
}

void calculate_cev();

//change for new
void solve_model()
{
	//static

	const int max_iter_agg = (env_max_iter_agg > 0) ? env_max_iter_agg : 1000;
	iter_agg = 0;
	while_stop_value = 0;

	do {

		r0 = (1.0 - update_step1) * r1 + update_step1 * r0;
		w0 = (1.0 - update_step1) * w1 + update_step1 * w0;
		theta_ut = (1.0 - update_step1) * theta_ut_new + update_step1 * theta_ut;
		
		if (r0 < 0.001) {
			r0 = 0.001;
		}

		// NEW: Handle tax rate updating
		if (use_fixed_tax_rate) {
			if (use_deadweight_loss) {
				tau_y0 = tau_y_baseline * tau_y_dwl_multiplier;  // Higher tax rate
			} else {
				tau_y0 = tau_y_baseline;  // Regular fixed tax
			}
		}
		else {
			tau_y0 = (1.0 - update_step1) * tau_y1 + update_step1 * tau_y0;
		}

		rho_aver = rho_aver_new;

		//solve the model:
		policy_compute();
		debug_opt_n_policy_tails();

		iter_agg += 1;
		//simulate the economy & update agg. varibales.
		calculate_cev();
		simulation();


		cout << "***************interest rate**************************" << endl;
		cout << "old interest: " << r0 << "   new interest r: " << r1 << endl;
		cout << "old wage: " << w0 << "   new wage: " << w1 << endl;
		cout << "old theta: " << theta_ut << "   new theta: " << theta_ut_new << endl;
		
		// NEW: Report lump-sum tax if using fixed tax regime
		if (use_fixed_tax_rate) {
			cout << "FIXED tau_y (baseline): " << tau_y0 << endl;
			cout << "Endogenous lump-sum tax: " << t_lumpsum_endogenous << endl;
			if (t_lumpsum_endogenous > 0) {
				cout << "  (positive = lump-sum TAX)" << endl;
			} else {
				cout << "  (negative = lump-sum TRANSFER)" << endl;
			}
		}

		cout << "iter_agg times" << iter_agg << endl;

		ofstream file;

		file.open(workingpath_new + "check_agg_change.txt", ios::app);

		file << r0 << " " << r1 << " " << w0 << " " << w1 << " " << tau_y0 << " " << tau_y1 << " " << theta_ut << " " << theta_ut_new;
		
		// NEW: Add lump-sum tax to output
		if (use_fixed_tax_rate) {
			file << " " << t_lumpsum_endogenous;
		}
		file << endl;

	} while (!check_agg() && iter_agg < max_iter_agg && while_stop_value == 0);

	while_stop_value = 0;

}

void calibra()
{

	//*******************************************
	for (int i_x = 0; i_x < Nx; i_x++) {
		for (int i_e = 0; i_e < Ne; i_e++) {
			x_shk[i_x][i_e] = x_shk[i_x][i_e] * x_scale;
		}
	}
	pi_x_input();

	solve_model();

}

//run policy experiments:
void policy_exp();
void policy_to_do();


int main(void)
{

	time_t start, end;
	time(&start);

	//+++++++++++++++++++++++++++++++++++++++++++
	//policy:
	//+++++++++++++++++++++++++++++++++++++++++++
	//financial friction
	r_wedge = 0.0;
	//insurance channel:
	agg_coins = 1.0;

	real_gdp = 49269.0;
	//***********************************

	//+++++++++++++++++++++++++++++++++++++++++++
	//assign values for parameters
	update_value = 0.95-0.05;	
	N_iter = 1000;	
			
	//+++++++++++++++++++++++++++++++++++++++++++
	cout<<"here: "<<" update_value: "<<update_value<<endl;
	apply_runtime_overrides();
	
	// NEW: First, find baseline equilibrium tax rate
	tau_y_baseline = -999.0;  // Will be set by case 101
	
	//std::vector<int> cases_to_run = { 101, 132, 133, 112, 113, 114, 115, 116, 117 };
	//std::vector<int> cases_to_run = { 101, 113, 114, 115, 116, 117 };
	//std::vector<int> cases_to_run = { 101, 134, 135, 136, 137, 113};
	// case 113 must run after 101.
	std::vector<int> cases_to_run = { 101, 102, 103, 113};
	if (env_single_case > 0) {
		cases_to_run = { env_single_case };
	}
	//122, 123, 
	//std::vector<int> cases_to_run = { 101, 132, 133 };

	//=====================================================
	// Special run mode: compute CASE 113 only using homotopy
	// If the user sets cases_to_run = {113}, we automatically:
	//   (1) run a baseline 101 warmup (in a separate folder, not overwriting prior results)
	//   (2) run case 113 along a continuation path for lowerincome_b: 0.40 -> 0.10
	//       keeping value/policy functions as initial guesses between steps
	//   (3) write the FINAL (b=0.10) results into the normal case 113 folder
	//=====================================================
	if (cases_to_run.size() == 1 && cases_to_run[0] == 113) {
		// -------------------------
		// 1) Warmup: baseline 101
		// -------------------------
		best_check_tol = 10.0;
		while_stop_value = 0;
		iter_agg = 0;

		i_case = 101;
		workingpath_new = workingpath + "data/Output/case_test_new_101_warmup113/";

		#ifdef _WIN32
			if (_access(workingpath_new.c_str(), 0)) {
				_mkdir(workingpath_new.c_str());
			}
		#else
			if (access(workingpath_new.c_str(), F_OK) != 0) {
				mkdir(workingpath_new.c_str(), 0755);
			}
		#endif

		override_lowerincome_b = env_override_lowerincome_b;
		if (env_override_lowerincome_b) {
			lowerincome_b_override = env_lowerincome_b;
		}
		assign_value();
		initialize_value();

		gn_decompose = 0.0;
		gn_exp = 0.0;
		r_decompose = 0.0;
		r_wedge_decompose = 0.0;
		r_wedge_exp = 0.0;
		ind_policy = 0;
		update_step1 = update_value;
		var_pE = 0.0;
		dummy_UI = 0.0;

		calibra();
		tau_y_baseline = tau_y0;
		cout << "[homotopy] Baseline (101) warmup done. tau_y_baseline = " << tau_y_baseline << endl;

		// -------------------------
		// 2) Homotopy path for case 113
		// -------------------------
		//std::vector<double> b_path = { 0.40, 0.35, 0.325, 0.30, 0.275, 0.25, 0.225, 0.20, 0.175 };
		std::vector<double> b_path = { 0.40, 0.35, 0.30, 0.275, 0.25, 0.225, 0.20, 0.175, 0.15, 0.125, 0.10, 0.075, 0.05 };
		bool first_step = true;

		for (double b_val : b_path) {
			best_check_tol = 10.0;
			while_stop_value = 0;
			iter_agg = 0;

			i_case = 113;

			// Folder handling:
			//  - intermediate steps go to dedicated homotopy folders
			//  - final step (b=0.10) goes to the standard case 113 folder
			std::ostringstream oss;
			oss << std::fixed << std::setprecision(2) << b_val;
			std::string b_tag = oss.str();
			std::replace(b_tag.begin(), b_tag.end(), '.', 'p');

			if (fabs(b_val - 0.10) < 1e-12) {
				workingpath_new = workingpath + "data/Output/case_test_new_113/";
			} else {
				workingpath_new = workingpath + "data/Output/case_test_new_113_homotopy_b" + b_tag + "/";
			}

			#ifdef _WIN32
				if (_access(workingpath_new.c_str(), 0)) {
					_mkdir(workingpath_new.c_str());
				}
			#else
				if (access(workingpath_new.c_str(), F_OK) != 0) {
					mkdir(workingpath_new.c_str(), 0755);
				}
			#endif

			override_lowerincome_b = true;
			lowerincome_b_override = b_val;

			assign_value();
			// IMPORTANT: do NOT call initialize_value() here.
			// We keep value/policy functions and equilibrium guesses from the previous step
			// (baseline for first_step, then previous b_val thereafter).
			if (first_step) {
				cout << "[homotopy] Starting case 113 from baseline solution at lowerincome_b=" << b_val << endl;
				first_step = false;
			} else {
				cout << "[homotopy] Continuing case 113 at lowerincome_b=" << b_val << endl;
			}

			gn_decompose = 0.0;
			gn_exp = 0.0;
			r_decompose = 0.0;
			r_wedge_decompose = 0.0;
			r_wedge_exp = 0.0;
			ind_policy = 0;
			update_step1 = update_value;
			var_pE = 0.0;
			dummy_UI = 0.0;

			calibra();
		}

		return 0;
	}
	
	for (int i_case_ind : cases_to_run) {
	//for (int i_case_ind = 101; i_case_ind < 120; i_case_ind++) {

		best_check_tol = 10.0;
		while_stop_value = 0;
		iter_agg = 0;
		

		string path_add_case = to_string(i_case_ind);
		i_case = i_case_ind;
		workingpath_new = workingpath + "data/Output/case_test_new_" + path_add_case + "/";

		int mode_exist_path = 0;
		#ifdef _WIN32
			if (_access(workingpath_new.c_str(), mode_exist_path))
			{
				_mkdir(workingpath_new.c_str());
			}
		#else
			if (access(workingpath_new.c_str(), F_OK) != 0)
			{
				mkdir(workingpath_new.c_str(), 0755);
			}
		#endif

		override_lowerincome_b = false;
		assign_value();
		initialize_value();

		gn_decompose = 0.0;
		gn_exp = 0.0;
		r_decompose = 0.0;
		r_wedge_decompose = 0.0;
		r_wedge_exp = 0.0;
		
		//+++++++++++++++++++++++++++++++++++++++++++
		//Baseline or Policy Experiment:
		//+++++++++++++++++++++++++++++++++++++++++++
				
		ind_policy = 0;
		update_step1 = update_value;
		var_pE = 0.0;
		dummy_UI = 0.0;


		calibra();
		
		// NEW: If this is baseline, save the equilibrium tax rate
		if (i_case == 101) {
			tau_y_baseline = tau_y0;  // Save baseline equilibrium tax rate
			cout << "***************BASELINE TAX RATE FOUND**************************" << endl;
			cout << "Baseline equilibrium tau_y = " << tau_y_baseline << endl;
			
			// Save to file
			// Save to file
			ofstream baseline_file(workingpath + "data/Output/baseline_equilibrium.txt");
			baseline_file << "Baseline equilibrium tau_y: " << tau_y_baseline << endl;
			baseline_file << "Baseline total tax revenue: " << baseline_total_tax << endl;
			baseline_file << "Baseline UI spending: " << baseline_UI_spending << endl;
			baseline_file << "Baseline consumption floor spending: " << baseline_cfloor_spending << endl;
			baseline_file << "Baseline total govt spending: " << baseline_govt_spending << endl;
			baseline_file << "Budget balance (should be ~0): " << baseline_total_tax - baseline_govt_spending << endl;
			baseline_file.close();
		}

		gn_exp1 = gn_ben1;
		gn_exp2 = gn_ben2;
		r_ben = r1;

		//+++++++++++++++++++++++++++++++++++++++++++
		//step #: report the running time.
		time(&end);
		DP  dif = difftime(end, start);
		cout << "Running time: " << dif / 60 << " minutes." << endl;
	}

	return 0;
}

//sub-routines:
void policy_to_do()
{
	solve_model();

}



void policy_exp()
// didn't used in the running part.
//10.29.2025
{
	//+++++++++++++++++++++++++++++++++++++++++++
	//+++++++++++++++++++++++++++++++++++++++++++
	//policy 1:                    
	//Provide EHI to the entire economy:
	//+++++++++++++++++++++++++++++++++++++++++++
	//+++++++++++++++++++++++++++++++++++++++++++

	ind_indemnity = 0.0;


	//initial conditons:
	r0 = 0.0833044;
	w0 = 0.79;
	c_EHI0 = 0.0702167;
	ave_earning0 = 1.51;
	t_lumpsum0 = 0.025;

	ind_policy = 1;
	update_step1 = update_value;
	var_pE = 1.0;
	dummy_UI = 0.0;

	policy_to_do();

	//+++++++++++++++++++++++++++++++++++++++++++
	//+++++++++++++++++++++++++++++++++++++++++++

	//initial conditons:
	r0 = 0.08168;
	w0 = 0.9034;
	c_EHI0 = 0.0;

	ave_earning0 = 1.6253;
	t_lumpsum0 = 0.0715;

	ind_policy = 3;
	update_step1 = update_value;
	var_pE = 1.0;
	dummy_UI = 1.0;
	c_EHI0 = 0.0;

	policy_to_do();

	//+++++++++++++++++++++++++++++++++++++++++++
	//+++++++++++++++++++++++++++++++++++++++++++
	//policy 4:
	//No EHI.
	//+++++++++++++++++++++++++++++++++++++++++++
	//+++++++++++++++++++++++++++++++++++++++++++	  

	ind_indemnity = 1.0;


	//initial conditons:
	r0 = 0.0829632;
	w0 = 0.806921;
	c_EHI0 = 0.0672;
	ave_earning0 = 1.61828;
	t_lumpsum0 = 0.0341;

	ind_policy = 4;
	update_step1 = update_value;
	var_pE = 0.0;
	dummy_UI = 0.0;
	c_EHI0 = 0.0;


	policy_to_do();


}
//change for edu dim
void calculate_cev()
{
	double tmp_cev0, tmp_cev1, tmp_cev;
	if (ind_policy == 0) {
		for (int i_e = 0; i_e < Ne; i_e++) {
			for (int i_a = 0; i_a < Na; i_a++) {
				for (int i_x = 0; i_x < Nx; i_x++) {
					for (int i_z = 0; i_z < Nz; i_z++) {
						for (int i_occp = 0; i_occp < Ni; i_occp++) {
							v_ben[i_a][i_x][i_occp][i_e] = v1[i_a][i_x][i_occp][i_e];
						}
					}
				}
			}
		}
	}
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {

					tmp_cev0 = 1.0 / (1.0 - sigma) / (1.0 - beta);
					tmp_cev1 = (v1[i_a][i_x][i_occp][i_e] + tmp_cev0) / (v_ben[i_a][i_x][i_occp][i_e] + tmp_cev0);
					tmp_cev = pow(tmp_cev1, 1.0 / (1.0 - sigma)) - 1.0;

					cev[i_a][i_x][i_occp][i_e] = tmp_cev;
				}
			}
		}
	}
	cout << "end caculate_Cev" << endl;
}
//++++++++++++++++++++++++++++++++++++++++++
//parameters related:
//++++++++++++++++++++++++++++++++++++++++++

//+++++++++++++++++++++++++++++++++++++++++++
//find optimal k for entrepreneurs:
//+++++++++++++++++++++++++++++++++++++++++++
double a_constrained_func(DP x)
{
	double rev_tmp1, rev_tmp2, rev_tmp3, k_tmp, n_tmp;
	double x_pE, x_gn, w_tmp, w_tmp1;

	n_tmp = x;

	//w_tmp = w0 * (1 + x0_credit);
	w_tmp = w0;

	rev_tmp1 = w_tmp * z_agg * n_tmp;

	k_tmp = pow(x0_credit * alpha / (1.0 + r_wedge) / r0 * pow(z_agg * n_tmp, gamma_param), 1.0 / (1.0 - alpha));

	rev_tmp2 = x0_credit * pow(k_tmp, alpha) * pow(z_agg * n_tmp, gamma_param);

	rev_tmp3 = 0.0;
	if (k_tmp < a0_credit - m0_credit) {
		rev_tmp3 = r0 * k_tmp;
	}
	else if (k_tmp >= a0_credit - m0_credit) {
		rev_tmp3 = r0 * (a0_credit - m0_credit) + (1.0 + r_wedge) * r0 * (k_tmp - (a0_credit - m0_credit));
	}

	return rev_tmp3 + rev_tmp1 - rev_tmp2;
}

double a_unconstrained_func(DP x)
{
	double rev_tmp1, rev_tmp2, rev_tmp3, k_tmp, n_tmp, t_tmp;
	double x_pE, x_gn, w_tmp, w_tmp1;

	n_tmp = x;
	w_tmp = w0;

	t_tmp = z_agg * w_tmp * (1 + psi * tau) + (kappa * w_tmp * rho_aver * z_agg) / theta_ut;
	k_tmp = pow((r0 / x0_credit) * pow((z_agg * r0 * gamma_param) / (alpha * t_tmp), -gamma_param) * (1 / alpha), 1 / (alpha + gamma_param - 1));

	rev_tmp1 = gamma_param * x0_credit * pow(k_tmp, alpha) * z_agg * pow(n_tmp, gamma_param - 1);
	rev_tmp2 = w_tmp * (1 + psi * tau) + (kappa * rho_aver) / theta_ut;

	return fabs(rev_tmp1 - rev_tmp2);
}

//solve for optimal k when the firm is credit-constrained:
void k_opt_constrained(double& a0_in, double& x0_in, double& n_in)
{
	a0_credit = a0_in;
	x0_credit = x0_in;

	n_credit = n_in;

	//initalization for finding the optimum
	const DP TOL = 1.0e-12, EQL = 1.0e-10;
	bool newroot;
	int j;
	int nmin = 0;
	DP ax, bx, cx;
	DP xmin1, xmin2;
	Vec_DP amin(60);

	nmin = 0;
	ax = 0.001;
	bx = n_credit / 2;
	cx = n_credit;

	//solving optimal a'.
	NR::brent(ax, bx, cx, a_constrained_func, TOL, xmin1);
	if (nmin == 0) {
		amin[nmin++] = xmin1;
	}
	else {
		newroot = true;
		for (j = 0; j < nmin; j++) {
			if (fabs(xmin1 - amin[j]) <= (EQL * xmin1)) newroot = false;
			if (newroot) {
				amin[nmin++] = xmin1;
			}
		}
	}
	double rev_tmp, k_tmp, n_tmp;
	n_tmp = xmin1;

	if (n_credit <= 0.001 || n_tmp < 0.001) {
		n_tmp = 0.001;
	}

	double k_tmp1, k_tmp2;
	k_tmp1 = x0_credit * alpha / (1.0 + r_wedge) / r0;

	//need to write a function to solve for n_tmp, since the wage is a function of n.
	k_tmp = pow(k_tmp1 * pow(n_tmp * z_agg, gamma_param), 1.0 / (1.0 - alpha));

	rev_tmp = -a_constrained_func(xmin1);

	if (n_tmp < 0.001) {
		n_tmp = 0.001;
		rev_tmp = 0.0;
	}

	output_constrained[0] = k_tmp;     //k_opt
	output_constrained[1] = n_tmp;      //n_opt
	output_constrained[2] = rev_tmp;      //rev_opt
}

void find_credit_const()
{
	ofstream file(workingpath_new + "credit_const_v18.txt");
	file.precision(4);

	double x_tmp, a_tmp, m_tmp, rev_tmp, k_tmp, n_tmp;
	double n_tmp1, n_tmp2;
	double k_star_tmp, n_star_tmp, rev_star_tmp;
	double k_opt_tmp, n_opt_tmp, rev_opt_tmp;
	double y_tmp, w0_with_edu;
	double T_tmp;

	//change for edu dim
	k_opt_tmp = 0, n_opt_tmp = 0, rev_opt_tmp = 0;
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_x = 0; i_x < Nx; i_x++)
		{

			//dim education dependent x_share(alpha and gamma)
			alpha = alpha_edu[i_e];
			gamma_param = gamma_edu[i_e];

			x_tmp = x_shk[i_x][i_e];
			//change for new question for w0
			w0_with_edu = w0;

			x0_credit = x_tmp;
			
			//w0_with_edu = edu_share[0] * w0 * (1 + edu_z[0]) + edu_share[1] * w0 * (1 + edu_z[1]) + edu_share[2] * w0 * (1 + edu_z[2]);

			T_tmp = z_agg * w0_with_edu * (1 + psi * tau) + (kappa * w0_with_edu * rho_aver * z_agg) / theta_ut;

			//T_tmp = z_agg * w0_with_edu * (1 + psi * tau) + (kappa * w0_with_edu * edu_rho[i_e] * z_agg) / theta_ut;

			k_star_tmp = pow((r0 / x_tmp) * pow((z_agg * r0 * gamma_param) / (alpha * T_tmp), -gamma_param) * (1 / alpha), 1 / (alpha + gamma_param - 1));

			n_star_tmp = (r0 * gamma_param) / (alpha * T_tmp) * k_star_tmp;

			//find n_star with non-linear g(n):
			if (x_tmp == 0.0) {
				n_star_tmp = n_star_tmp;
			}
			else if (x_tmp > 0.0)
			{
				//initalization for finding the optimum
				const DP TOL = 1.0e-12, EQL = 1.0e-10;
				bool newroot;
				int j;
				int nmin = 0;
				DP ax, bx, cx;
				DP xmin1, xmin2;
				Vec_DP amin(60);

				nmin = 0;
				ax = 0.001;
				bx = n_star_tmp / 2;
				cx = n_star_tmp;

				//solving optimal a'.
				NR::brent(ax, bx, cx, a_unconstrained_func, TOL, xmin1);
				if (nmin == 0) {
					amin[nmin++] = xmin1;
				}
				else {
					newroot = true;
					for (j = 0; j < nmin; j++) {
						if (fabs(xmin1 - amin[j]) <= (EQL * xmin1)) newroot = false;
						if (newroot) {
							amin[nmin++] = xmin1;
						}
					}
				}
				//
				n_star_tmp = xmin1;
			}

			y_tmp = x_tmp * pow(k_star_tmp, alpha) * pow(z_agg * n_star_tmp, gamma_param);
			// firm profit

			rev_star_tmp = y_tmp - z_agg * w0_with_edu * (1 + psi * tau) * n_star_tmp - r0 * k_star_tmp - (kappa * w0_with_edu * rho_aver * z_agg * n_star_tmp) / theta_ut;
			
			//rev_star_tmp = y_tmp - z_agg * w0_with_edu * (1 + psi * tau) * n_star_tmp - r0 * k_star_tmp - (kappa * w0_with_edu * edu_rho[i_e] * z_agg * n_star_tmp) / theta_ut;

			k_star_vec[i_x][i_e] = k_star_tmp;
			n_star_vec[i_x][i_e] = n_star_tmp;
			rev_star_vec[i_x][i_e] = rev_star_tmp;

			//change for no health
			if (n_star_tmp < 0.0) {
				n_star_tmp = 1e-5;
			}

			for (int i_a = 0; i_a < Na; i_a++) {

				a_tmp = a_vec[i_a];



				//out-of-pocket health spending:

				if (a_tmp >= k_star_tmp || x_tmp == 0.0) {
					k_opt_tmp = k_star_tmp;
					n_opt_tmp = n_star_tmp;
					rev_opt_tmp = rev_star_tmp;
				}
				else if (a_tmp < k_star_tmp && x_tmp > 0.0) {

					k_opt_constrained(a_tmp, x_tmp, n_star_tmp);
					k_opt_tmp = output_constrained[0];
					n_opt_tmp = output_constrained[1];
					rev_opt_tmp = output_constrained[2];
				}

				k_opt_vec[i_a][i_x][i_e] = k_opt_tmp;
				n_opt_vec[i_a][i_x][i_e] = n_opt_tmp;
				rev_opt_vec[i_a][i_x][i_e] = rev_opt_tmp;

				file << a_tmp << " " << x_tmp << " " << k_star_tmp << " " << rev_star_tmp << " " << k_opt_tmp << " " << n_opt_tmp << " " << rev_opt_tmp << endl;

			}//end i_a
		}//end i_x
	}
	cout << "find_credit_const" << endl;
}

//++++++++++++++++++++++++++++
//computation--iterations
//++++++++++++++++++++++++++++
//change for edu dim
void renew_functions()
{
	//change for no health
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					v0[i_a][i_x][i_occp][i_e] = v1[i_a][i_x][i_occp][i_e];
					opt_occp_0[i_a][i_x][i_occp][i_e] = opt_occp_1[i_a][i_x][i_occp][i_e];


					for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {

						opt_a_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_1[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_k_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_1[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_n_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_1[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_rev_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_1[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_c_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e];
					}
				}

			}
		}
	}

	//change for no health
	// we must go through all types of individual
	//change for edu
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx_iid; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {

					vx[i_a][i_x][i_occp][i_e] = 0;
					for (int i_x1 = 0; i_x1 < Nx; i_x1++) {
						// manage shock probability
						vx[i_a][i_x][i_occp][i_e] += pi_x_shk[i_x][i_x1][i_e] * v0[i_a][i_x1][i_occp][i_e];
					}
				}//end i_occp
			}//end i_x
		}//end i_a
	}
	//cout << "renew_functions" << endl;
}

//covergence tolerance for policy function iteration.
//change for no health 
//change for new i want to see whether it convergence or not
double check_value()
{
	ofstream file(workingpath_new + "useless_only_for_checktol.txt");

	bool ans = true;
	double count = 0;
	double v_dist = 0;

	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					count += 1;
					v_dist += fabs(v1[i_a][i_x][i_occp][i_e] / v0[i_a][i_x][i_occp][i_e] - 1.0);
				}
			}
		}
	}

	double check_tol = v_dist / count;
	//cout << "tol for value:" << check_tol << endl;
	return check_tol;
}

//covergence tolerance for policy function iteration.
bool check_agg()
{
	bool ans = true;
	if (fabs(r0 - r1) > tol_agg ||
		fabs(w0 - w1) > tol_agg ||
		fabs(theta_ut_new - theta_ut)> tol_agg||
		fabs(tau_y0 - tau_y1)>tol_agg
		) {
		return false;

	}
	return ans;
}

void debug_opt_n_policy_tails()
{
	struct TopState {
		double n_val;
		double p_work;
		int i_e;
		int i_occp_state;
		int i_a;
		int i_x;
		double a_val;
		double x_val;
	};

	const int top_n_states = 8;
	vector<TopState> top_states;

	double n_min = std::numeric_limits<double>::infinity();
	double n_max = -std::numeric_limits<double>::infinity();
	double k_min = std::numeric_limits<double>::infinity();
	double k_max = -std::numeric_limits<double>::infinity();
	double n_sum = 0.0;
	double k_sum = 0.0;
	long long n_count = 0;
	long long n_nonfinite = 0;
	long long k_nonfinite = 0;
	long long n_negative = 0;
	long long k_negative = 0;
	long long n_gt_10 = 0;
	long long n_gt_100 = 0;
	long long n_gt_1000 = 0;
	long long entr_state_count = 0;
	long long state_count = 0;

	for (int i_e = 0; i_e < Ne; ++i_e) {
		for (int i_occp_state = 0; i_occp_state < Ni; ++i_occp_state) {
			for (int i_a = 0; i_a < Na; ++i_a) {
				for (int i_x = 0; i_x < Nx; ++i_x) {
					const double n_val = opt_n_0[i_occp_state][0][i_a][i_x][i_e];
					const double k_val = opt_k_0[i_occp_state][0][i_a][i_x][i_e];
					const double p_work = opt_occp_0[i_a][i_x][i_occp_state][i_e];

					state_count += 1;
					if (p_work < 0.5) {
						entr_state_count += 1;
					}

					if (std::isfinite(n_val)) {
						n_min = std::min(n_min, n_val);
						n_max = std::max(n_max, n_val);
						n_sum += n_val;
						n_count += 1;
						if (n_val < 0.0) { n_negative += 1; }
						if (n_val > 10.0) { n_gt_10 += 1; }
						if (n_val > 100.0) { n_gt_100 += 1; }
						if (n_val > 1000.0) { n_gt_1000 += 1; }

						TopState candidate;
						candidate.n_val = n_val;
						candidate.p_work = p_work;
						candidate.i_e = i_e;
						candidate.i_occp_state = i_occp_state;
						candidate.i_a = i_a;
						candidate.i_x = i_x;
						candidate.a_val = a_vec[i_a];
						candidate.x_val = x_shk[i_x][i_e];
						if (static_cast<int>(top_states.size()) < top_n_states) {
							top_states.push_back(candidate);
						}
						else {
							auto min_it = std::min_element(
								top_states.begin(), top_states.end(),
								[](const TopState& lhs, const TopState& rhs) { return lhs.n_val < rhs.n_val; });
							if (min_it != top_states.end() && candidate.n_val > min_it->n_val) {
								*min_it = candidate;
							}
						}
					}
					else {
						n_nonfinite += 1;
					}

					if (std::isfinite(k_val)) {
						k_min = std::min(k_min, k_val);
						k_max = std::max(k_max, k_val);
						k_sum += k_val;
						if (k_val < 0.0) { k_negative += 1; }
					}
					else {
						k_nonfinite += 1;
					}
				}
			}
		}
	}

	const double n_avg = (n_count > 0) ? (n_sum / static_cast<double>(n_count)) : 0.0;
	const double k_avg = (n_count > 0) ? (k_sum / static_cast<double>(n_count)) : 0.0;
	const double entr_state_share = (state_count > 0) ? (static_cast<double>(entr_state_count) / static_cast<double>(state_count)) : 0.0;
	if (!std::isfinite(n_min)) { n_min = 0.0; }
	if (!std::isfinite(n_max)) { n_max = 0.0; }
	if (!std::isfinite(k_min)) { k_min = 0.0; }
	if (!std::isfinite(k_max)) { k_max = 0.0; }

	cout << "***************opt_n_0 policy tail diagnostics**************************" << endl;
	cout << "policy_state_count: " << state_count << "  entrepreneur_state_share: " << entr_state_share << endl;
	cout << "opt_n_0 min/max/avg: " << n_min << " / " << n_max << " / " << n_avg
		<< "  negatives: " << n_negative << "  nonfinite: " << n_nonfinite << endl;
	cout << "opt_n_0 tail counts (>10, >100, >1000): " << n_gt_10 << ", " << n_gt_100 << ", " << n_gt_1000 << endl;
	cout << "opt_k_0 min/max/avg: " << k_min << " / " << k_max << " / " << k_avg
		<< "  negatives: " << k_negative << "  nonfinite: " << k_nonfinite << endl;
	std::sort(
		top_states.begin(), top_states.end(),
		[](const TopState& lhs, const TopState& rhs) { return lhs.n_val > rhs.n_val; });
	cout << "opt_n_0 top states (n, p_work, edu, occp_state, a_idx, x_idx, a, x):" << endl;
	for (size_t i = 0; i < top_states.size(); ++i) {
		const TopState& s = top_states[i];
		cout << "  [" << i << "] "
			<< s.n_val << ", " << s.p_work
			<< ", e=" << s.i_e
			<< ", occp=" << s.i_occp_state
			<< ", a_idx=" << s.i_a
			<< ", x_idx=" << s.i_x
			<< ", a=" << s.a_val
			<< ", x=" << s.x_val << endl;
	}
}

void NRlocate(double xx[], int size, double x, int& j)
{
	int ju, jm, jl;
	bool ascnd;

	int n = size;
	jl = -1;
	ju = n;
	ascnd = (xx[n - 1] >= xx[0]);
	while (ju - jl > 1) {
		jm = (ju + jl) >> 1;
		if (x >= xx[jm] == ascnd)
			jl = jm;
		else
			ju = jm;
	}
	if (x == xx[0]) j = 0;
	else if (x == xx[n - 1]) j = n - 2;
	else j = jl;
}


double intp(double policy[Na][Nx_iid][Ni][Ne], double& a1_i, int& x_state_i, int ind_occp, int& edu_occp)
{
	int ia;
	NRlocate(a_vec, Na, a1_i, ia);
	if (ia < 0) { ia = 0; }
	if (ia >= Na - 2) { ia = Na - 2; }

	x_state_i = Nx_iid - 1;

	return (policy[ia + 1][x_state_i][ind_occp][edu_occp] - policy[ia][x_state_i][ind_occp][edu_occp])
		/ (a_vec[ia + 1] - a_vec[ia]) * (a1_i - a_vec[ia])
		+ policy[ia][x_state_i][ind_occp][edu_occp];
}

// import the initial policy functions.
//change for edu dim
void policy_input()
{
	//int k,l;
	string txt;
	ifstream fp(workingpath + "data/Input/CFV/policy_functions_v17_in.txt");

	// Corrected policy_input() function
	
	// 1. Check if the read operation was successful IN THE LOOP CONDITION
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na_in; i_a++) {
			for (int i_x = 0; i_x < Nx_in; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					for (int i_occp_en = 0; i_occp_en < Ni - 1; i_occp_en++) {
						
						double dg0, dg1, dg2, dg3, dg4, dg5, dg6, dg7, dg8, dg9;
	
						if (!(fp >> dg0 >> dg1 >> dg2 >> dg3 >> dg4 >> dg5 >> dg6 >> dg7 >> dg8 >> dg9)) {
							cerr << "ERROR: Read failed on or before line corresponding to:" << endl;
							cerr << "i_e=" << i_e << ", i_a=" << i_a << ", i_x=" << i_x << endl;
							fp.close();
							return; // Exit immediately upon failure
						}
						
						//cout<<dg0<<endl;
						// 2. Assign grid vectors ONLY ONCE per index to be efficient
						if (i_x == 0 && i_occp == 0 && i_occp_en == 0 && i_e == 0) {
							a_vec_in[i_a] = dg0;
						}
						if (i_a == 0 && i_occp == 0 && i_occp_en == 0 && i_e == 0) {
							x_shk_in[i_x] = dg1;
						}
	
						// Assign the actual policy values
						v_in[i_a][i_x][i_occp][i_e] = dg4;
						opt_a_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg5;
						opt_k_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg6;
						opt_n_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg7;
						opt_occp_in[i_a][i_x][i_occp][i_e] = dg9;
					}
				}
			}
			// This will now print the correctly and singly-assigned value
			//cout << a_vec_in[i_a] << endl; 
		}
	}
	fp.close();

	cout << "good:" << endl;

	//interpolate to generate finer grids.
	double tmp_a, tmp_x;

	//change for no new
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {

					tmp_a = a_vec[i_a];
					tmp_x = x_shk[i_x][i_e];
					//change for edu
					//cout << tmp_a << "  " << tmp_x << "  " << i_occp << endl;
					v1[i_a][i_x][i_occp][i_e] = intp_2d_in_4arg(tmp_a, tmp_x, i_occp, i_e, v_in);

					opt_occp_1[i_a][i_x][i_occp][i_e] = intp_2d_in_4arg(tmp_a, tmp_x, i_occp, i_e, opt_occp_in);


					if (opt_occp_1[i_a][i_x][i_occp][i_e] >= 0.5)
					{
						opt_occp_1[i_a][i_x][i_occp][i_e] = 1.0;
					}
					else if (opt_occp_1[i_a][i_x][i_occp][i_e] < 0.5)
					{
						opt_occp_1[i_a][i_x][i_occp][i_e] = 0.0;
					}

					//change for new
					for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {

						//change for new 
						opt_a_1[i_occp][i_occp_e][i_a][i_x][i_e] = intp_2d_in_6arg(tmp_a, tmp_x, i_occp, i_occp_e, i_e, opt_a_in);
						opt_k_1[i_occp][i_occp_e][i_a][i_x][i_e] = intp_2d_in_6arg(tmp_a, tmp_x, i_occp, i_occp_e, i_e, opt_k_in);
						opt_n_1[i_occp][i_occp_e][i_a][i_x][i_e] = intp_2d_in_6arg(tmp_a, tmp_x, i_occp, i_occp_e, i_e, opt_n_in);
					}

				}
			}
		}
	}
	//end intp

	cout << "good:" << endl;

}


//+++++++++++++++++++++++++++++++++++++++++++
//simulation related:
//+++++++++++++++++++++++++++++++++++++++++++

void gen_rnd()  // import the policy points.
{
	string txt;
	ifstream fp(workingpath + "data/Input/CFV/rnd_100k.txt");

	for (int i_rnd = 0; i_rnd < 3; i_rnd++) {
		for (int i_pd = 0; i_pd < Nsim_pd; i_pd++) {
			for (int i_ppl = 0; i_ppl < Nsim_ppl; i_ppl++) {
				double debug1;
				fp >> debug1;
				if (i_rnd == 0) {
					rnd_x_shk[i_pd][i_ppl] = debug1;
				}
			}
		}
	}
	cout << "rnd" << endl;
	fp.close();
}



//x_shock iid log normal:
void x_shk_input()
{
	string txt;
	ifstream fp(workingpath + "data/Input/CFV/x_shk_iid.txt");

	//x shock:
	for (int i_x = 0; i_x < Nx; i_x++) {

		double debug1, debug2, debug3;
		fp >> debug1 >> debug2 >> debug3;
		x_shk[i_x][0] = debug1;
		x_shk[i_x][1] = debug2;
		x_shk[i_x][2] = debug3;
		//cout << "debug1" << debug1 << "2" << debug2 << "3" << debug3 << endl;
	}

	fp.close();
}

void pi_x_input()
{
	string txt;
	ifstream fp(workingpath + "data/Input/CFV/input_pi_x_iid_1.txt");

	//x shock:
	x_shk_input();

	//Markov chain for x:
	for (int i_x2 = 0; i_x2 < Nx; i_x2++) {

		double debug1, debug2, debug3;
		fp >> debug1 >> debug2 >> debug3;
		pi_x_shk[0][i_x2][0] = debug1;
		pi_x_shk[0][i_x2][1] = debug2;
		pi_x_shk[0][i_x2][2] = debug3;

		pi_x_inv[i_x2][0] = pi_x_shk[0][i_x2][0];
		pi_x_inv[i_x2][1] = pi_x_shk[0][i_x2][1];
		pi_x_inv[i_x2][2] = pi_x_shk[0][i_x2][2];
	}
	fp.close();
}

//x_shock markov (now no use)
void pi_x_input_iid()
{
	//x shock:
	for (int i_x = 0; i_x < Nx; i_x++) {
		//x_shk[i_x][i_e] = (x_h - x_l) / (Nx - 1) * i_x + x_l;
	}

	//Markov chain for x:
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_x1 = 0; i_x1 < Nx; i_x1++) {
			for (int i_x2 = 0; i_x2 < Nx; i_x2++) {
				if (i_x2 == 0) {
					//pi_x_shk[i_x1][i_x2][i_e] = pow(x_shk[i_x2], 1.0 / x_eps);
				}
				else if (i_x2 > 0) {
					//pi_x_shk[i_x1][i_x2] = pow(x_shk[i_x2], 1.0 / x_eps) - pow(x_shk[i_x2 - 1], 1.0 / x_eps);
				}

				//invariant dist of x:
				//pi_x_inv[i_x2] = pi_x_shk[i_x1][i_x2];
			}
		}
	}


}

//x_shock persistent(now no use)
// not used. 10/29/2025
void pi_x_input_markov()
{
	//int k,l;
	string txt;
	ifstream fp(workingpath + "data/Input/CFV/input_pi_x.txt");

	//x shock:
	//x_shk[0] = 0.000 / x_scale;
	//x_shk[1] = 0.706 / x_scale;
	//x_shk[2] = 1.470 / x_scale;
	//x_shk[3] = 2.234 / x_scale;

	//invariant dist of x:
	//pi_x_inv[0] = 0.554;
	//pi_x_inv[1] = 0.283;
	//pi_x_inv[2] = 0.099;
	//pi_x_inv[3] = 0.064;

	//Markov chain for x:
	for (int i_x1 = 0; i_x1 < Nx; i_x1++) {
		for (int i_x2 = 0; i_x2 < Nx; i_x2++) {

			double debug;
			fp >> debug;
			//pi_x_shk[i_x1][i_x2] = debug;
		}
	}

	fp.close();
}

void comp_accum_x()
{
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_x0 = 0; i_x0 < Nx_iid; i_x0++) {
			for (int i_x1 = 0; i_x1 < Nx; i_x1++) {

				accum_x_shk[i_x0][i_x1][i_e] = 0.0;
				int tmp_i_x1;
				tmp_i_x1 = 0;

				do {
					accum_x_shk[i_x0][i_x1][i_e] += pi_x_shk[i_x0][tmp_i_x1][i_e];

					tmp_i_x1 += 1;
				} while (tmp_i_x1 < i_x1 + 1);

				accum_x_shk[i_x0][Nx - 1][i_e] = 1.0;
			}
		}

	}
	cout << "comp_accu" << endl;
}

double x0_rnd(double& rnd_x_in, int& x_sim_state, int& edu_occp)
{
	double x0_sim_out;

	x_sim_state = Nx_iid - 1;

	int i_x1 = Nx;
	do {
		i_x1 += (-1);
	} while (rnd_x_in < accum_x_shk[x_sim_state][i_x1][edu_occp] && i_x1 > -1);

	x0_sim_out = x_shk[i_x1 + 1][edu_occp];

	return x0_sim_out;
}

double x0_rnd_intial(double& rnd_x_in, int& edu_occp)
{
	double x0_sim_out;

	int i_x1 = Nx;
	do {
		i_x1 += (-1);
	} while (rnd_x_in < accum_x_shk[0][i_x1][edu_occp] && i_x1 > -1);

	x0_sim_out = x_shk[i_x1 + 1][edu_occp];

	return x0_sim_out;
}


//Bilinear interpolation:
//change for edu dim
double intp_2d(double& x_a0, double& x_x0,
	int& i_x_occp, int& x_occp0, int& edu_occp,
	double policy[Ni][Ni - 1][Na][Nx][Ne])
{
	const double a_eval = clamp_value(x_a0, a_vec[0], a_vec[Na - 1]);
	int i_a0;
	NRlocate(a_vec, Na, a_eval, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na - 1) { i_a0 = Na - 2; }

	
	for (int i_x = 0; i_x < Nx; i_x++) {
		forNR_x_shk[i_x] = x_shk[i_x][edu_occp];
	}
	const double x_eval = clamp_value(x_x0, forNR_x_shk[0], forNR_x_shk[Nx - 1]);
	int i_x0;
	NRlocate(forNR_x_shk, Nx, x_eval, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx - 1) { i_x0 = Nx - 2; }

	double fa, fb, fc, fd, ft, fu;

	fa = policy[i_x_occp][x_occp0][i_a0][i_x0][edu_occp];
	fb = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0][edu_occp];
	fc = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0 + 1][edu_occp];
	fd = policy[i_x_occp][x_occp0][i_a0][i_x0 + 1][edu_occp];

	ft = (a_eval - a_vec[i_a0]) / (a_vec[i_a0 + 1] - a_vec[i_a0]);
	if (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp] <= 0.0000001) {
		fu = (x_eval - x_shk[i_x0][edu_occp]);
	}
	else {
		fu = (x_eval - x_shk[i_x0][edu_occp]) / (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp]);
	}

	return (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd;
}

//change for edu dim

double intp_2d_opt(double& x_a0, double& x_x0, int& x_occp0, int& edu_occp,
	double policy[Na][Nx][Ni][Ne])
{
	const double a_eval = clamp_value(x_a0, a_vec[0], a_vec[Na - 1]);
	int i_a0;
	NRlocate(a_vec, Na, a_eval, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na - 1) { i_a0 = Na - 2; }
	
	for (int i_x = 0; i_x < Nx; i_x++) {
		forNR_x_shk[i_x] = x_shk[i_x][edu_occp];
	}
	const double x_eval = clamp_value(x_x0, forNR_x_shk[0], forNR_x_shk[Nx - 1]);
	int i_x0;
	NRlocate(forNR_x_shk, Nx, x_eval, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx - 1) { i_x0 = Nx - 2; }

	double fa, fb, fc, fd, ft, fu;
	fa = policy[i_a0][i_x0][x_occp0][edu_occp];
	fb = policy[i_a0 + 1][i_x0][x_occp0][edu_occp];
	fc = policy[i_a0 + 1][i_x0 + 1][x_occp0][edu_occp];
	fd = policy[i_a0][i_x0 + 1][x_occp0][edu_occp];

	ft = (a_eval - a_vec[i_a0]) / (a_vec[i_a0 + 1] - a_vec[i_a0]);
	if (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp] <= 0.0000001) {
		fu = (x_eval - x_shk[i_x0][edu_occp]);
	}
	else {
		fu = (x_eval - x_shk[i_x0][edu_occp]) / (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp]);
	}

	//cout << "intp 2d opt " << fa << "   " << fb << "   " << fc << "   " << fd << "   " <<ft << "   " << fu<< endl;
	return (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd;
}
//change for edu dim
int intp_occp_sim(double& a0_in, double& x0_in, int& x_occp0, int& edu_occp)
{
	double occp_tmp;
	int i_occp_out;
	//change for no health

	occp_tmp = intp_2d_opt(a0_in, x0_in, x_occp0, edu_occp, opt_occp_0);
	//cout << "count occp_tmp" << occp_tmp << endl;
	if (occp_tmp <= 0.5) {
		i_occp_out = 0;
	}
	else if (occp_tmp > 0.5) {
		i_occp_out = 1;
	}
	//cout << "count i_occp_out" << i_occp_out << endl;
	return i_occp_out;
}

double intp_opt_sim(double& a0_in, double& x0_in, int& i_x_occp, int& i_occp0_in, int& edu_occp,
	double opt_in[Ni][Ni - 1][Na][Nx][Ne])
{
	//cout << "iovvp_in" << i_occp0_in << endl;
	double opt_out;
	opt_out = intp_2d(a0_in, x0_in, i_x_occp, i_occp0_in, edu_occp, opt_in);
	return opt_out;
}



double intp_2d_in_6arg(double& x_a0, double& x_x0, int& i_x_occp, int& x_occp0, int& edu_occp, double policy[Ni][Ni - 1][Na_in][Nx_in][Ne])
{
	const double a_eval = clamp_value(x_a0, a_vec_in[0], a_vec_in[Na_in - 1]);
	const double x_eval = clamp_value(x_x0, x_shk_in[0], x_shk_in[Nx_in - 1]);
	int i_a0;
	NRlocate(a_vec_in, Na_in, a_eval, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na_in - 1) { i_a0 = Na_in - 2; }

	int i_x0;
	NRlocate(x_shk_in, Nx_in, x_eval, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx_in - 1) { i_x0 = Nx_in - 2; }

	double fa, fb, fc, fd, ft, fu;

	//change for no health
	fa = policy[i_x_occp][x_occp0][i_a0][i_x0][edu_occp];
	fb = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0][edu_occp];
	fc = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0 + 1][edu_occp];
	fd = policy[i_x_occp][x_occp0][i_a0][i_x0 + 1][edu_occp];

	ft = (a_eval - a_vec_in[i_a0]) / (a_vec_in[i_a0 + 1] - a_vec_in[i_a0]);
	fu = (x_eval - x_shk_in[i_x0]) / (x_shk_in[i_x0 + 1] - x_shk_in[i_x0]);

	return (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd;
}

//change for edu dim
double intp_2d_in_4arg(double& x_a0, double& x_x0, int& xi_occp, int& edu_occp,
	double policy[Na_in][Nx_in][Ni][Ne])
{
	//cout << x_a0 << "     " << x_x0 << endl;

	int i_a0;
	NRlocate(a_vec_in, Na_in, x_a0, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na_in - 1) { i_a0 = Na_in - 2; }

	int i_x0;
	NRlocate(x_shk_in, Nx_in, x_x0, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx_in - 1) { i_x0 = Nx_in - 2; }
	//cout << i_a0 << "     " << i_x0 << endl;
	double fa, fb, fc, fd, ft, fu;

	//change for no health
	fa = policy[i_a0][i_x0][xi_occp][edu_occp];
	fb = policy[i_a0 + 1][i_x0][xi_occp][edu_occp];
	fc = policy[i_a0 + 1][i_x0 + 1][xi_occp][edu_occp];
	fd = policy[i_a0][i_x0 + 1][xi_occp][edu_occp];

	ft = (x_a0 - a_vec_in[i_a0]) / (a_vec_in[i_a0 + 1] - a_vec_in[i_a0]);
	fu = (x_x0 - x_shk_in[i_x0]) / (x_shk_in[i_x0 + 1] - x_shk_in[i_x0]);
	//cout << fa << "   " << fb << "   " << fc << "   " << fd << "   " << ft << "   " << fu << endl;

	//cout << (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd << endl;



	return (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd;
}
//***************************************************************
