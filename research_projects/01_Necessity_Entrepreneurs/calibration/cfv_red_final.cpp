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
#include <direct.h>
#include <fstream>
#include <algorithm>
#include <string>
#include <io.h>


using namespace std; //standard namespace


string workingpath = "F:\\study\\CFKL\\code\\CFKL_par_1\\";
string workingpath_new;

//***********//
//parameters:
//***********//

double best_check_tol = 10.0;

double x_share_edu[3], k_share;
double beta, alpha_edu[3], gamma_edu[3], x_eps, alpha = 0.0, gamma = 0.0;             //discount, capital share, x distribution.
double psi, tau, tau_pi, tau_y, kappa;   //
double mu, bar_m; //search rate
double sigma;
const int Nm = 7;                      //grid for medical spending.

double output_opt[8];
double tfp;
double theta, q_A, b_E;
int while_stop_value;

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

//*******************//
//aggregate variables:
//*******************//
double z_agg;
double theta_ut,theta_ut_new, v_t, u_t, rho_aver, rho_aver_new; //matching
double emp_rate;
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


double prob_unemp;

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
double x0_sim[Nsim_ppl], a0_sim[Nsim_ppl], n0_sim[Nsim_ppl];//change for no health
int occp0_sim[Nsim_ppl];
double a1_sim[Nsim_ppl], n_sim[Nsim_ppl], c_sim[Nsim_ppl], k0_sim[Nsim_ppl];
int i_occp0_sim[Nsim_ppl];
double y_sim[Nsim_ppl], cev_sim[Nsim_ppl];

int i_case;

//Transition
//for transition matrixs//
const int T = 40;
double Value_T[T][Na][Nx][Ni][Ne];                                     //value functions: (T, a, x, iloc, edu)-->Value Transition.
double opt_occp_T[T][Na][Nx][Ni][Ne];                     //policy function: (a, x, edu)-->occp choice transition
double opt_a_T[T][Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->asset transition
double opt_k_T[T][Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->loan transition
double opt_n_T[T][Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->n demand transition
double opt_rev_T[T][Ni][Ni - 1][Na][Nx][Ne];
double opt_c_T[T][Ni][Ni - 1][Na][Nx][Ne];

int occp_T_sim[T][Nsim_ppl];
int i_occp_T_sim[T][Nsim_ppl];
double a_T_sim[T][Nsim_ppl], x_T_sim[T][Nsim_ppl], n_T_sim[T][Nsim_ppl], c_T_sim[T][Nsim_ppl], k_T_sim[T][Nsim_ppl];

//save ge results
double best_r, best_w, best_theta_ut, best_z_agg, best_rho_aver;
double Value_best[Na][Nx][Ni][Ne];                                     //value functions: (T, a, x, iloc, edu)-->Value Transition.
double opt_occp_best[Na][Nx][Ni][Ne];                     //policy function: (a, x, edu)-->occp choice transition
double opt_a_best[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->asset transition
double opt_k_best[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->loan transition
double opt_n_best[Ni][Ni - 1][Na][Nx][Ne];           //policy function: (I, i_E, a, x, edu)-->n demand transition
double opt_rev_best[Ni][Ni - 1][Na][Nx][Ne];
double opt_c_best[Ni][Ni - 1][Na][Nx][Ne];
double a_best_sim[Nsim_ppl], x_best_sim[Nsim_ppl], n_best_sim[Nsim_ppl], c_best_sim[Nsim_ppl], k_best_sim[Nsim_ppl];
int occp_best_sim[Nsim_ppl];
int i_occp_best_sim[Nsim_ppl];


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
	nrerror("Too many iterations in brent");
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
	double pent;
	pent = 0.0;

	//consumption:

	c0 = income_tmp - a1;

	double utility;

	//utility = log(c0); 
	utility = (pow(c0, 1.0 - sigma) - 1.0) / (1.0 - sigma);

	//need take care of c<0.0;	
	double c_tmp = 1e-3;
	double u_tmp;

	if (c0 < c_tmp) {

		u_tmp = (pow(c_tmp, 1.0 - sigma) - 1.0) / (1.0 - sigma);
		utility = u_tmp - (u_tmp - (-10000.0)) * (c_tmp - c0);
	}

	double a_prime, expt_value;
	expt_value = 0.0;
	//exp value function

		//expt_value = expt_v(a1, x_state, 1);//now = 1+2

	expt_value = expt_v(a1, x_state, i_occp_through[0], i_edu_occp);

	double u_v_1 = -(utility + beta * expt_value);

	c0 = income_tmp_un - a1;

	//utility = log(c0); 
	utility = (pow(c0, 1.0 - sigma) - 1.0) / (1.0 - sigma);

	//need take care of c<0.0;	

	if (c0 < c_tmp) {

		u_tmp = (pow(c_tmp, 1.0 - sigma) - 1.0) / (1.0 - sigma);
		utility = u_tmp - (u_tmp - (-10000.0)) * (c_tmp - c0);
	}

	expt_value = 0.0;
	//exp value function

	expt_value = expt_v(a1, x_state, i_occp_through[1], i_edu_occp);//more dim for edu

	double u_v_2 = -(utility + beta * expt_value);

	return prob_unemp * u_v_1 + (1 - prob_unemp) * u_v_2;// + pent;
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

	//change for new in this part individual's income have a prob for emp or unemp so we add a new input para- prob_unemp

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

		income_tmp = (1 + r0 - dep_k) * a0 + (1 - prob_rho) * (z0 * w0_tmp * (1 - (1 - psi) * tau_y0)) + prob_rho * lowerincome_b * w0_tmp;

		income_tmp_un = (1 + r0 - dep_k) * a0 + prob_theta_u * (z0 * w0_tmp * (1 - (1 - psi) * tau_y0)) + (1 - prob_theta_u) * lowerincome_b * w0_tmp;
		//different people may face different income
		if (i_occp0 == 1) // currently employed
		{
			cx = income_tmp;
			double mid_exchange = 0.0;
			mid_exchange = income_tmp;
			income_tmp = income_tmp_un;
			income_tmp_un = mid_exchange;
		}
		else if (i_occp0 == 2) // currently unemployed
		{
			cx = income_tmp_un;
		}
		else if (i_occp0 == 0) // currently enterprenur
		{
			cx = income_tmp_un;
		}


		if (bx > cx) {
			bx = (ax + cx) / 2.0;
		}

		if (i_occp0 == 1)
		{
			prob_unemp = prob_rho;
			i_occp_through[0] = 2;
			i_occp_through[1] = 1;
		}
		else if (i_occp0 == 2)
		{
			prob_unemp = prob_theta_u;
			i_occp_through[0] = 1;
			i_occp_through[1] = 2;
		}
		else if (i_occp0 == 0)
		{
			prob_unemp = prob_theta_u;
			i_occp_through[0] = 1;
			i_occp_through[1] = 2;
		}

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

		income_tmp = (1 + r0 - dep_k) * a0 + rev_opt - tau_pi;
	
	
		cx = income_tmp;

		if (bx > cx) {
			bx = (ax + cx) / 2.0;
		}


		//check
		prob_unemp = 0.5; // this probability is not actually used
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
			gamma = gamma_edu[i_e];

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
							opt_c_1[i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[6];
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
		if (iter > 1000) {
			while_stop_value = 1;
		}
		//check value tol
		cout << "iter times:" << iter << "   " << check_value() << "   " << theta_ut << endl;

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

	double tax_income, total_tax;


	double agg_y_sim;
	int ppl_edu;
	int cacu_0 = 0, cacu_1 = 0, cacu_2 = 0;

	double v_t, u_t, ave_rho, cacu_1_rho = 0, random_num = 0.0;
	double total_lower_out;


	int cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;

	for (int t_sim = 0; t_sim < Nsim_pd; t_sim++) {
		srand((int)time(0));//setting random seed
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

		cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;
		


		if (t_sim == 0) {
			theta_ut_new = 0.6;
			rho_aver_new = 0.03;
		}
		else {
			// cacu rho and theta

			ave_rho = 0.0;
			cacu_1_rho = 0.0;

			cacu_0 = 0;
			cacu_1 = 0;
			cacu_2 = 0;

			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
				if (ppl_sim < edu_share[0] * Nsim_ppl) {
					ppl_edu = 0;
				}
				else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
					ppl_edu = 1;
				}
				else {
					ppl_edu = 2;
				}
				a0_sim_tmp = a0_sim[ppl_sim];
				x0_sim_tmp = x0_sim[ppl_sim];
				occp0_sim_tmp = occp0_sim[ppl_sim];

				i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);

				if (i_occp0_sim_tmp == 0) {
					cacu_0 += 1;//en
				}
				else if (i_occp0_sim_tmp == 1) {
					if (occp0_sim[ppl_sim] == 2.0 || occp0_sim[ppl_sim] == 0.0) {
						cacu_2 += 1;
					}
					else if (occp0_sim[ppl_sim] == 1.0) {
						cacu_1 += 1;
						cacu_1_rho += edu_rho[ppl_edu];
					}
				}
			}

			v_t = cacu_1_rho;
			u_t = cacu_2;
			theta_ut_new = bar_m * pow((v_t / u_t), 1 - mu);
			rho_aver_new = cacu_1_rho / cacu_1;//old rho

			//ave_work_prob = (cacu_2 * theta_ut_new + cacu_1 * (1 - ave_rho)) / (cacu_2 + cacu_1);//the real worker's prob
			//cout << "ave work prob: " << ave_work_prob << "  " << theta_ut_new << "  " << ave_rho << "  " << cacu_1_rho << "  " << u_t << "  " << cacu_0 << "  " << cacu_2 << endl;
		}



		for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
			if (ppl_sim < edu_share[0] * Nsim_ppl) {
				ppl_edu = 0;
			}
			else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
				ppl_edu = 1;
			}
			else {
				ppl_edu = 2;
			}
			//ave_rho = edu_rho[ppl_edu];//new rho
			// dim education dependent x_share(alpha and gamma)

			alpha = alpha_edu[ppl_edu];
			gamma = gamma_edu[ppl_edu];

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
				a0_sim[ppl_sim] = a1_sim[ppl_sim];
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

			i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);
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
				if (occp0_sim_tmp == 2 || occp0_sim_tmp == 0) {
					z_agg += (1 + edu_z[ppl_edu]) * theta_ut_new;//if from umep to work
				}
				else if (occp0_sim[ppl_sim] == 1) {
					z_agg += (1 + edu_z[ppl_edu]) * (1 - edu_rho[ppl_edu]);//if still work
				}
				

				//cout << "4" << endl;
			}
			else if (i_occp0_sim_tmp == 0) {
				//change for edu dim
				n0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_n_0);

				k0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_k_0);

				y_sim[ppl_sim] = i_occp0_sim_tmp * x0_sim_tmp * pow(k0_sim_tmp, alpha) * pow(n0_sim_tmp, gamma);

				agg_y_sim += y_sim[ppl_sim];

				//cout << "5" << endl;
			}

			n_sim[ppl_sim] = n0_sim_tmp;

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
					if (random_num <= theta_ut_new) {
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
					
					if (random_num <= edu_rho[ppl_edu]) {
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


			earning_sim += income_sim;
			asset_demand += k0_sim_tmp;
			asset_supply += a0_sim_tmp;

		}
	}
	cout << "" << endl;
	cout << "***************test prob and real prob**************************" << endl;
	cout << "in rand unemp prob: " << cacu_unemp / (cacu_tot_unemp + 1.0) << "  with real prob:" << theta_ut_new << endl;
	cout << "in rand emp prob: " << cacu_emp / (cacu_tot_emp + 1.0) << "  with real prob:" << 1.0 - rho_aver_new << endl;
	//cacu new theta_ut_new
	ave_rho = 0.0;
	cacu_1_rho = 0.0;
	cacu_0 = 0;
	cacu_1 = 0;
	cacu_2 = 0;

	for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
		if (ppl_sim < edu_share[0] * Nsim_ppl) {
			ppl_edu = 0;
		}
		else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
			ppl_edu = 1;
		}
		else {
			ppl_edu = 2;
		}
		a0_sim_tmp = a0_sim[ppl_sim];
		x0_sim_tmp = x0_sim[ppl_sim];
		occp0_sim_tmp = occp0_sim[ppl_sim];
		i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);
		if (i_occp0_sim_tmp == 0) {
			cacu_0 += 1;//en
		}
		else if (i_occp0_sim_tmp == 1) {
			if (occp0_sim[ppl_sim] == 2 || occp0_sim[ppl_sim] == 0) {
				cacu_2 += 1;
			}
			else if (occp0_sim[ppl_sim] == 1) {
				cacu_1 += 1;
				cacu_1_rho += edu_rho[ppl_edu];
			}
		}
	}
	v_t = cacu_1_rho;
	u_t = cacu_2;
	theta_ut_new = bar_m * pow((v_t / u_t), 1 - mu);
	rho_aver_new = cacu_1_rho / cacu_1;


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

	emp_rate = 0.0;


	for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

		a0_sim_tmp = a0_sim[ppl_sim];// individual's asset
		x0_sim_tmp = x0_sim[ppl_sim];// x
		occp0_sim_tmp = occp0_sim[ppl_sim];// now location
		i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);// use policy to cacu next loc: choose work or entr

		//set edu & cacu distribution
		if (ppl_sim < edu_share[0] * Nsim_ppl) {
			ppl_edu = 0;
			if (i_occp0_sim_tmp == 0) {
				if (occp0_sim_tmp == 0) {
					entr_edu_0_0 += 1. / (Nsim_ppl * edu_share[0]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_0_0 += 1. / (Nsim_ppl * edu_share[0]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_0_0 += 1. / (Nsim_ppl * edu_share[0]);
				}
			}
			else if (i_occp0_sim_tmp == 1) {//want to work
				if (occp0_sim_tmp == 0) {
					entr_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
				}
			}
		}
		else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
			ppl_edu = 1;
			if (i_occp0_sim_tmp == 0) {
				if (occp0_sim_tmp == 0) {
					entr_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
				}
			}
			else if (i_occp0_sim_tmp == 1) {//want to work
				if (occp0_sim_tmp == 0) {
					entr_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
				}
			}
		}
		else {
			ppl_edu = 2;
			if (i_occp0_sim_tmp == 0) {
				if (occp0_sim_tmp == 0) {
					entr_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
				}
			}
			else if (i_occp0_sim_tmp == 1) {//want to work
				if (occp0_sim_tmp == 0) {
					entr_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
				}
				else if (occp0_sim_tmp == 1) {
					emp_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
					emp_rate += 1. / Nsim_ppl;
				}
				else if (occp0_sim_tmp == 2) {
					unemp_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
				}
			}
		}

	}

	cout << "" << endl;
	cout << "***************unemployment rate in different edu**************************" << endl;
	cout << "edu level 0:   the unemp rate:" << unemp_edu_1_0 << "  the entr rate: " << entr_edu_1_0 << "  the working rate: " << emp_edu_1_0 << endl;
	cout << "edu level 1:   the unemp rate:" << unemp_edu_1_1 << "  the entr rate: " << entr_edu_1_1 << "  the working rate: " << emp_edu_1_1 << endl;
	cout << "edu level 2:   the unemp rate:" << unemp_edu_1_2 << "  the entr rate: " << entr_edu_1_2 << "  the working rate: " << emp_edu_1_2 << endl;
	cout << "emp rate"<< emp_rate << endl;

	double tmp_a0, tmp_x0, tmp_cev;
	int tmp_z0, tmp_m0, tmp_i_HI0;
	//changed line
	ofstream file_2(workingpath_new + "sim_v18.txt");
	ave_welfare = 0.0;
	for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

		tmp_a0 = a0_sim[ppl_sim];
		tmp_x0 = x0_sim[ppl_sim];
		occp0_sim_tmp = occp0_sim[ppl_sim];

		tmp_cev = intp_2d_opt(tmp_a0, tmp_x0, occp0_sim_tmp, ppl_edu, cev);
		cev_sim[ppl_sim] = tmp_cev;

		ave_welfare += tmp_cev;

		file_2 << a0_sim[ppl_sim] << " " << x0_sim[ppl_sim] << " "
			<< a1_sim[ppl_sim] << " " << i_occp0_sim[ppl_sim] << " " << n_sim[ppl_sim] << " " << k0_sim[ppl_sim] << " " << y_sim[ppl_sim] << " "
			<< cev_sim[ppl_sim] << endl;
	}
	file_2.close();


	//calculate aggregate variables.
	r1 = (1.0 - r_decompose) * (1.0 + (asset_demand - asset_supply) / ((asset_demand + asset_supply) / 2.0)) * r0 + r_decompose * r_ben;
	w1 = (1.0 + (n_demand - n_supply) / ((n_demand + n_supply) / 2.0)) * w0;
	//cout << "7.5" << endl;

	ave_earning1 = earning_sim / Nsim_ppl;

	tau_y1 = total_lower_out / earning_wkr;// cacu need out num
	t_lumpsum1 = total_lower_out / Nsim_ppl;

	if (ind_policy == 0) {
		t_lumpsum_ben = t_lumpsum1 / ave_earning1;
	}

	if (dummy_UI == 1) {
		t_lumpsum1 = t_lumpsum_ben * ave_earning1;
	}

	agg_cfloor_transfer = agg_cfloor_transfer / Nsim_ppl;
	n_cfloor_transfer = n_cfloor_transfer / Nsim_ppl;

	a_y = asset_supply / agg_y_sim;
	k_y = asset_demand / agg_y_sim;

	//health insurance
	earning_wkr = earning_wkr / n_supply;
	earning_entr = earning_entr / entr_ratio;



	//firm dist.
	firm_size = n_demand / entr_ratio;
	firm_big = firm_big / entr_ratio;

	entr_ratio = entr_ratio / Nsim_ppl;

	gdp1 = agg_y_sim;
	ave_welfare = ave_welfare / Nsim_ppl;

	z_agg = z_agg / n_supply;

	cout << "" << endl;
	cout << "***************some simulation result**************************" << endl;
	cout << "sim ans nsup: " << n_supply <<"   ndemand: " << n_demand << "  " << z_agg << endl;
	cout << "sim next pi tau y  " << tau_y1 << endl;
	cout << "sim ans tax part with tax: " << total_tax << "  with out lower income: " << total_lower_out << endl;

	//cout << "best_tol in model now" << best_check_tol << endl;
}

//change for no health
void assign_value()
{
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
	emp_rate = 0.8;

	tau_pi = 0;
	psi = 0;

	kappa = 0.03; //with w

	mu = 0.6;
	bar_m = 1;
	lowerincome_b = 0.4;

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
	z_agg = 1.00331;
	theta_ut = 0.25;
	theta_ut_new = theta_ut;

	r1 = r0;
	w1 = w0;
	c_EHI1 = c_EHI0;
	tau_y1 = tau_y0;
	gdp1 = gdp0;
	ave_earning1 = ave_earning0;
	t_lumpsum1 = t_lumpsum0;

	govt = 0.2;
	cout << "initialize_value" << endl;
}

void calculate_cev();

//change for new
void solve_model()
{
	static

	int iter_agg = 0;
	double tol_ge = 0.0;

	while_stop_value = 0;
	do {

		r0 = (1.0 - update_step1) * r1 + update_step1 * r0;
		w0 = (1.0 - update_step1) * w1 + update_step1 * w0;
		theta_ut = (1.0 - update_step1) * theta_ut_new + update_step1 * theta_ut;

		//tau_y0 = (1.0 - update_step1) * tau_y1 + update_step1 * tau_y0;
		tau_y0 = tau_y0;

		rho_aver = rho_aver_new;

		//c_EHI0 = c_EHI1;
		//ave_earning0 = ave_earning1;
		//t_lumpsum0 = t_lumpsum1;

		//solve the model:
		policy_compute();

		iter_agg += 1;
		//simulate the economy & update agg. varibales.
		calculate_cev();                                 //calculate the welfare cost.
		simulation();


		cout << "***************interest rate**************************" << endl;
		cout << "old interest: " << r0 << "   new interest r: " << r1 << endl;
		cout << "old wage: " << w0 << "   new wage: " << w1 << endl;
		cout << "old theta: " << theta_ut << "   new theta: " << theta_ut_new << endl;

		cout << "iter_agg times" << iter_agg << endl;

		ofstream file;

		file.open(workingpath_new + "check_agg_change.txt", ios::app);
		   
		file << r0 << " " << r1 << " " << w0 << " " << w1 << " " << tau_y0 << " " << tau_y1<<"" << theta_ut << " " << theta_ut_new << endl;

		tol_ge = abs(r1 - r0) + abs(w1 - w0) + abs(theta_ut - theta_ut_new);
		if (tol_ge <= best_check_tol) {
			best_check_tol = tol_ge;
			best_r = r0;
			best_w = w0;
			best_theta_ut = theta_ut;
			best_z_agg = z_agg;
			best_rho_aver = rho_aver;

			for (int i_e = 0; i_e < Ne; i_e++) {
				for (int i_a = 0; i_a < Na; i_a++) {
					for (int i_x = 0; i_x < Nx; i_x++) {
						for (int i_occp = 0; i_occp < Ni; i_occp++) {
							Value_best[i_a][i_x][i_occp][i_e] = v0[i_a][i_x][i_occp][i_e];
							opt_occp_best[i_a][i_x][i_occp][i_e] = opt_occp_0[i_a][i_x][i_occp][i_e];
							for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
								opt_a_best[i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_0[i_occp][i_occp_e][i_a][i_x][i_e];
								opt_k_best[i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_0[i_occp][i_occp_e][i_a][i_x][i_e];
								opt_n_best[i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_0[i_occp][i_occp_e][i_a][i_x][i_e];
								opt_rev_best[i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_0[i_occp][i_occp_e][i_a][i_x][i_e];
								opt_c_best[i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_0[i_occp][i_occp_e][i_a][i_x][i_e];
							}
						}
					}
				}
			}

			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
				a_best_sim[ppl_sim] = a0_sim[ppl_sim];
				x_best_sim[ppl_sim] = x0_sim[ppl_sim];
				n_best_sim[ppl_sim] = n0_sim[ppl_sim];
				c_best_sim[ppl_sim] = c_sim[ppl_sim];
				k_best_sim[ppl_sim] = k0_sim[ppl_sim];

				occp_best_sim[ppl_sim] = occp0_sim[ppl_sim];
				i_occp_best_sim[ppl_sim] = i_occp0_sim[ppl_sim];
			}
		}
			

	} while (!check_agg() && iter_agg < 500 && while_stop_value == 0);

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

	//financial friction
	r_wedge = 0.0;
	//insurance channel:
	agg_coins = 1.0;

	real_gdp = 49269.0;

	workingpath_new = workingpath + "data/Output/case_1/";
	int mode_exist_path = 0;
	if (_access(workingpath_new.c_str(), mode_exist_path))
	{
		_mkdir(workingpath_new.c_str());
	}
	//begin initial eq solve
	//begin params

	best_check_tol = 10.0;

	assign_value();
	beta = 0.94;
	double x_share_dims[3] = { 0.782, 0.802, 0.822 };

	for (int i_loop = 0; i_loop < 3; i_loop++) {
		x_share_edu[i_loop] = x_share_dims[i_loop];
	}

	bar_m = 0.9;
	mu = 0.68;
	kappa = 0.035;
	tau_y0 = 0.036874;

	for (int i_loop = 0; i_loop < 3; i_loop++) {
		alpha_edu[i_loop] = k_share * x_share_edu[i_loop];
		gamma_edu[i_loop] = (1.0 - k_share) * x_share_edu[i_loop];
		cout << " alpha_i " << alpha_edu[i_loop] << " gamma_i " << gamma_edu[i_loop] << " xshare" << x_share_edu[i_loop] << endl;
	}

	lowerincome_b = 0.3;

	//begin solve
	initialize_value();

	gn_decompose = 0.0;
	gn_exp = 0.0;
	r_decompose = 0.0;
	r_wedge_decompose = 0.0;
	r_wedge_exp = 0.0;

	ind_policy = 0;
	update_step1 = 0.95;
	var_pE = 0.0;
	dummy_UI = 0.0;


	calibra();

	gn_exp1 = gn_ben1;
	gn_exp2 = gn_ben2;
	r_ben = r1;

	gn_decompose = 0.0;
	gn_exp = 0.0;
	r_decompose = 0.0;
	r_wedge_decompose = 0.0;
	r_wedge_exp = 0.0;

	//time(&end);
	//DP  dif = difftime(end, start);
	//cout << "Finish initial eq. Running time: " << dif / 60 << " minutes." << endl;

	//save initial policies/values/dists
	//policys/values
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					Value_T[0][i_a][i_x][i_occp][i_e] = Value_best[i_a][i_x][i_occp][i_e];
					opt_occp_T[0][i_a][i_x][i_occp][i_e] = opt_occp_best[i_a][i_x][i_occp][i_e];
					for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
						opt_a_T[0][i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_k_T[0][i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_n_T[0][i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_rev_T[0][i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_c_T[0][i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_best[i_occp][i_occp_e][i_a][i_x][i_e];
					}
				}
			}
		}
	}

	//dists
	for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
		a_T_sim[0][ppl_sim] = a_best_sim[ppl_sim];
		x_T_sim[0][ppl_sim] = x_best_sim[ppl_sim];
		n_T_sim[0][ppl_sim] = n_best_sim[ppl_sim];
		c_T_sim[0][ppl_sim] = c_best_sim[ppl_sim];
		k_T_sim[0][ppl_sim] = k_best_sim[ppl_sim];

		occp_T_sim[0][ppl_sim] = occp_best_sim[ppl_sim];
		i_occp_T_sim[0][ppl_sim] = i_occp_best_sim[ppl_sim];

	}


	//params
	double init_r, init_w, init_theta_ut, init_z_agg, init_rho_aver;
	init_r = best_r;
	init_w = best_w;
	init_theta_ut = best_theta_ut;
	init_z_agg = best_z_agg;
	init_rho_aver = best_rho_aver;
	
	//solve final eqs
	//begin params


	//begin solve
	best_check_tol = 10.0;

	assign_value();

	lowerincome_b = 0.25;

	initialize_value();

	gn_decompose = 0.0;
	gn_exp = 0.0;
	r_decompose = 0.0;
	r_wedge_decompose = 0.0;
	r_wedge_exp = 0.0;

	ind_policy = 0;
	update_step1 = 0.95;
	var_pE = 0.0;
	dummy_UI = 0.0;


	calibra();

	gn_exp1 = gn_ben1;
	gn_exp2 = gn_ben2;
	r_ben = r1;

	gn_decompose = 0.0;
	gn_exp = 0.0;
	r_decompose = 0.0;
	r_wedge_decompose = 0.0;
	r_wedge_exp = 0.0;

	//time(&end);
	//DP  dif = difftime(end, start);
	//cout << "Finish final eq. Running time: " << dif / 60 << " minutes." << endl;

	//save final policies/values/dists
	//policys/values
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na; i_a++) {
			for (int i_x = 0; i_x < Nx; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					Value_T[T-1][i_a][i_x][i_occp][i_e] = Value_best[i_a][i_x][i_occp][i_e];
					opt_occp_T[T - 1][i_a][i_x][i_occp][i_e] = opt_occp_best[i_a][i_x][i_occp][i_e];
					for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
						opt_a_T[T - 1][i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_k_T[T - 1][i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_n_T[T - 1][i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_rev_T[T - 1][i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_best[i_occp][i_occp_e][i_a][i_x][i_e];
						opt_c_T[T - 1][i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_best[i_occp][i_occp_e][i_a][i_x][i_e];
					}
				}
			}
		}
	}

	//dists
	for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
		a_T_sim[T - 1][ppl_sim] = a_best_sim[ppl_sim];
		x_T_sim[T - 1][ppl_sim] = x_best_sim[ppl_sim];
		n_T_sim[T - 1][ppl_sim] = n_best_sim[ppl_sim];
		c_T_sim[T - 1][ppl_sim] = c_best_sim[ppl_sim];
		k_T_sim[T - 1][ppl_sim] = k_best_sim[ppl_sim];

		occp_T_sim[T - 1][ppl_sim] = occp0_sim[ppl_sim];
		i_occp_T_sim[T - 1][ppl_sim] = i_occp0_sim[ppl_sim];

	}

	//params
	double final_r, final_w, final_theta_ut, final_z_agg, final_rho_aver;
	final_r = best_r;
	final_w = best_w;
	final_theta_ut = best_theta_ut;
	final_z_agg = best_z_agg;
	final_rho_aver = best_rho_aver;

	//calculate policy from 2 to T-1
	//get param path
	double lowerincome_b_path[T];

	double r_path[T];
	double w_path[T];
	double theta_ut_path[T];
	double z_agg_path[T];
	double rho_aver_path[T];

	//new param path
	double r_path_new[T];
	double w_path_new[T];
	double theta_ut_path_new[T];
	double z_agg_path_new[T];
	double rho_aver_path_new[T];

	double tol_param_path;
	tol_param_path = 1.0;

	for (int i_t = 0; i_t < T; i_t++) {
		if (i_t == 0) {
			lowerincome_b_path[i_t] = 0.3;
			r_path[i_t] = init_r;
			w_path[i_t] = init_w;
			theta_ut_path[i_t] = init_theta_ut;
			z_agg_path[i_t] = init_z_agg;
			rho_aver_path[i_t] = init_rho_aver;

			r_path_new[i_t] = init_r;
			w_path_new[i_t] = init_w;
			theta_ut_path_new[i_t] = init_theta_ut;
			z_agg_path_new[i_t] = init_z_agg;
			rho_aver_path_new[i_t] = init_rho_aver;
		}
		else if(i_t > T * 1.0 / 2) {
			lowerincome_b_path[i_t] = 0.25;
			r_path[i_t] = final_r;
			w_path[i_t] = final_w;
			theta_ut_path[i_t] = final_theta_ut;
			z_agg_path[i_t] = final_z_agg;
			rho_aver_path[i_t] = final_rho_aver;

			r_path_new[i_t] = final_r;
			w_path_new[i_t] = final_w;
			theta_ut_path_new[i_t] = final_theta_ut;
			z_agg_path_new[i_t] = final_z_agg;
			rho_aver_path_new[i_t] = final_rho_aver;
		}
		else {
			lowerincome_b_path[i_t] = 0.25;
			r_path[i_t] = (final_r - init_r) / (T * 1. / 2.) * i_t + init_r;
			w_path[i_t] = (final_w - init_w) / (T * 1. / 2.) * i_t + init_w;
			theta_ut_path[i_t] = (final_theta_ut - init_theta_ut) / (T * 1. / 2.) * i_t + init_theta_ut;
			z_agg_path[i_t] = (final_z_agg - init_z_agg) / (T * 1. / 2.) * i_t + init_z_agg;
			rho_aver_path[i_t] = (final_rho_aver - init_rho_aver) / (T *1. /2.) * i_t + init_rho_aver;

		}		
	}
	int loop_trans_iter;
	loop_trans_iter = 0;

	do{
		//params
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

		for (int i_t = T - 2; i_t > 0; i_t--) {
			lowerincome_b = lowerincome_b_path[i_t];
			r0 = r_path[i_t];
			w0 = w_path[i_t];
			theta_ut = theta_ut_path[i_t];
			z_agg = z_agg_path[i_t];
			rho_aver = rho_aver_path[i_t];

			//renew value function
			for (int i_e = 0; i_e < Ne; i_e++) {
				for (int i_a = 0; i_a < Na; i_a++) {
					for (int i_x = 0; i_x < Nx; i_x++) {
						for (int i_occp = 0; i_occp < Ni; i_occp++) {
							v0[i_a][i_x][i_occp][i_e] = Value_T[i_t + 1][i_a][i_x][i_occp][i_e];
							opt_occp_0[i_a][i_x][i_occp][i_e] = opt_occp_T[i_t + 1][i_a][i_x][i_occp][i_e];

							for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
								opt_a_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_T[i_t + 1][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_k_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_T[i_t + 1][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_n_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_T[i_t + 1][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_rev_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_T[i_t + 1][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_c_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_T[i_t + 1][i_occp][i_occp_e][i_a][i_x][i_e];
							}
						}
					}
				}
			}

			for (int i_e = 0; i_e < Ne; i_e++) {
				for (int i_a = 0; i_a < Na; i_a++) {
					for (int i_x = 0; i_x < Nx_iid; i_x++) {
						for (int i_occp = 0; i_occp < Ni; i_occp++) {
							vx[i_a][i_x][i_occp][i_e] = 0;
							for (int i_x1 = 0; i_x1 < Nx; i_x1++) {
								vx[i_a][i_x][i_occp][i_e] += pi_x_shk[i_x][i_x1][i_e] * v0[i_a][i_x1][i_occp][i_e];
							}
						}//end i_occp
					}//end i_x
				}//end i_a
			}

			find_credit_const();

			for (int i_e = 0; i_e < Ne; i_e++) {
				rho_edu_i = edu_rho[i_e];
				i_edu_occp = i_e;
				alpha = alpha_edu[i_e];
				gamma = gamma_edu[i_e];

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
								opt_a_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[1];
								opt_k_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[2];
								opt_n_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[3];
								opt_rev_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[5];
								opt_c_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e] = output_opt[6];
							}

							ev_tmp_wkr = ev_tmp_grid[1];
							ev_tmp_entr = ev_tmp_grid[0];


							v_next_time = 0.0;
							if (ev_tmp_wkr >= ev_tmp_entr - 0.000001) {
								opt_occp_T[i_t][i_a][i_x][i_occp][i_e] = 1.0;
								v_next_time = ev_tmp_wkr;
							}

							//to be an entrepreure:
							else if (ev_tmp_wkr < ev_tmp_entr) {
								opt_occp_T[i_t][i_a][i_x][i_occp][i_e] = 0.0;
								v_next_time = ev_tmp_entr;
							}
							Value_T[i_t][i_a][i_x][i_occp][i_e] = v_next_time;
						}
					} //end i_a
				} //end i_x
			}
		}

		//do simulation from 1 to T-1

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

		double tax_income, total_tax;

		double agg_y_sim;
		int ppl_edu;
		int cacu_0 = 0, cacu_1 = 0, cacu_2 = 0;

		double v_t, u_t, ave_rho, cacu_1_rho = 0, random_num = 0.0;
		double total_lower_out;


		int cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;

		for (int i_t = 1; i_t < T - 1; i_t++) {
			//policy get
			for (int i_e = 0; i_e < Ne; i_e++) {
				for (int i_a = 0; i_a < Na; i_a++) {
					for (int i_x = 0; i_x < Nx; i_x++) {
						for (int i_occp = 0; i_occp < Ni; i_occp++) {
							v0[i_a][i_x][i_occp][i_e] = Value_T[i_t][i_a][i_x][i_occp][i_e];
							opt_occp_0[i_a][i_x][i_occp][i_e] = opt_occp_T[i_t][i_a][i_x][i_occp][i_e];
							for (int i_occp_e = 0; i_occp_e < Ni - 1; i_occp_e++) {
								opt_a_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_a_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_k_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_k_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_n_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_n_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_rev_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_rev_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e];
								opt_c_0[i_occp][i_occp_e][i_a][i_x][i_e] = opt_c_T[i_t][i_occp][i_occp_e][i_a][i_x][i_e];
							}
						}
					}
				}
			}
			//simulation

			srand((int)time(0));//setting random seed
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

			cacu_emp = 0, cacu_unemp = 0, cacu_tot_emp = 0, cacu_tot_unemp = 0;

			// cacu rho and theta
			ave_rho = 0.0;
			cacu_1_rho = 0.0;
			cacu_0 = 0;
			cacu_1 = 0;
			cacu_2 = 0;

			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
				if (ppl_sim < edu_share[0] * Nsim_ppl) {
					ppl_edu = 0;
				}
				else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
					ppl_edu = 1;
				}
				else {
					ppl_edu = 2;
				}
				a0_sim_tmp = a_T_sim[i_t - 1][ppl_sim];
				x0_sim_tmp = x_T_sim[i_t - 1][ppl_sim];
				occp0_sim_tmp = occp_T_sim[i_t - 1][ppl_sim];

				i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);
				i_occp_T_sim[i_t][ppl_sim] = i_occp0_sim_tmp;

				if (i_occp0_sim_tmp == 0) {
					cacu_0 += 1;//en
				}
				else if (i_occp0_sim_tmp == 1) {
					if (occp0_sim_tmp == 2.0 || occp0_sim_tmp == 0.0) {
						cacu_2 += 1;
					}
					else if (occp0_sim_tmp == 1.0) {
						cacu_1 += 1;
						cacu_1_rho += edu_rho[ppl_edu];
					}
				}
			}

			v_t = cacu_1_rho;
			u_t = cacu_2;
			theta_ut_new = bar_m * pow((v_t / u_t), 1 - mu);
			rho_aver_new = v_t / cacu_1;//old rho


			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {
				if (ppl_sim < edu_share[0] * Nsim_ppl) {
					ppl_edu = 0;
				}
				else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
					ppl_edu = 1;
				}
				else {
					ppl_edu = 2;
				}

				alpha = alpha_edu[ppl_edu];
				gamma = gamma_edu[ppl_edu];

				//current asset:
				//a0_sim[ppl_sim] = a_T_sim[i_t-1][ppl_sim];

				tmp_x_rnd = rnd_x_shk[i_t - 1][ppl_sim];
				i_x_prev = x_T_sim[i_t - 1][ppl_sim];

				x_T_sim[i_t][ppl_sim] = x0_rnd(tmp_x_rnd, i_x_prev, ppl_edu);

				//current period state: {a, x, occp, i_occp}:
				a0_sim_tmp = a_T_sim[i_t - 1][ppl_sim];
				x0_sim_tmp = x_T_sim[i_t][ppl_sim];
				occp0_sim_tmp = occp_T_sim[i_t - 1][ppl_sim];

				i_occp0_sim_tmp = i_occp_T_sim[i_t][ppl_sim];

				entr_ratio += 1.0 - i_occp0_sim_tmp;

				//labor demand:
				if (i_occp0_sim_tmp == 1) {
					n0_sim_tmp = 1.0;
					k0_sim_tmp = 0.0;
					y_sim[ppl_sim] = 0.0;
					agg_y_sim += y_sim[ppl_sim];

					if (occp0_sim_tmp == 2.0 || occp0_sim_tmp == 0.0) {
						z_agg += (1 + edu_z[ppl_edu]) * theta_ut_new;//if from umep to work
					}
					else if (occp0_sim[ppl_sim] == 1.0) {
						z_agg += (1 + edu_z[ppl_edu]) * (1 - edu_rho[ppl_edu]);//if still work
					}
				}
				else if (i_occp0_sim_tmp == 0) {
					//change for edu dim
					n0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_n_0);
					k0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_k_0);

					y_sim[ppl_sim] = i_occp0_sim_tmp * x0_sim_tmp * pow(k0_sim_tmp, alpha) * pow(n0_sim_tmp, gamma);
					agg_y_sim += y_sim[ppl_sim];
				}

				n_T_sim[i_t][ppl_sim] = n0_sim_tmp;

				a1_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_a_0);
				c0_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_c_0);
				rev_sim_tmp = intp_opt_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, i_occp0_sim_tmp, ppl_edu, opt_rev_0);

				c_T_sim[i_t][ppl_sim] = c0_sim_tmp;

				//income:
				double w0_tmp, pi_subsidy_tmp;
				w0_tmp = w0;


				//decisions:
				a_T_sim[i_t][ppl_sim] = a1_sim_tmp;

				//desisions for real occp and prob
				if (i_occp0_sim_tmp == 0) {// to be an en
					occp_T_sim[i_t][ppl_sim] = 0;
				}
				else {// to be a worker
					if (occp0_sim_tmp == 0 || occp0_sim_tmp == 2) {// unemploy
						random_num = ((double)rand()) / RAND_MAX;
						//cout << random_num << endl;
						if (random_num <= theta_ut_new) {
							occp_T_sim[i_t][ppl_sim] = 1;
							cacu_unemp += 1;
						}
						else {
							occp_T_sim[i_t][ppl_sim] = 2;//unep
						}
						cacu_tot_unemp += 1;

					}
					else if (occp0_sim_tmp == 1) {// employ
						random_num = ((double)rand()) / RAND_MAX;

						if (random_num <= edu_rho[ppl_edu]) {
							occp_T_sim[i_t][ppl_sim] = 2;//unep
						}
						else {
							occp_T_sim[i_t][ppl_sim] = 1;
							cacu_emp += 1;
						}
						cacu_tot_emp += 1;
					}
				}

				//calculate aggregate variables
				occp0_sim_tmp = occp_T_sim[i_t][ppl_sim];

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
				earning_sim += income_sim;
				asset_demand += k0_sim_tmp;
				asset_supply += a0_sim_tmp;

			}

			//cout << "" << endl;
			//cout << "***************test prob and real prob**************************" << endl;
			//cout << "in rand unemp prob: " << cacu_unemp / (cacu_tot_unemp + 1.0) << "  with real prob:" << theta_ut_new << endl;
			//cout << "in rand emp prob: " << cacu_emp / (cacu_tot_emp + 1.0) << "  with real prob:" << 1.0 - rho_aver_new << endl;

			//cacu unemployment rate for how many nowadays people will unemp in next day with diff edu
			double unemp_edu_0_0, unemp_edu_1_0, unemp_edu_0_1, unemp_edu_1_1, unemp_edu_0_2, unemp_edu_1_2;
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

			emp_rate = 0.0;

			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

				a0_sim_tmp = a0_sim[ppl_sim];// individual's asset
				x0_sim_tmp = x0_sim[ppl_sim];// x
				occp0_sim_tmp = occp0_sim[ppl_sim];// now location
				i_occp0_sim_tmp = intp_occp_sim(a0_sim_tmp, x0_sim_tmp, occp0_sim_tmp, ppl_edu);// use policy to cacu next loc: choose work or entr

				//set edu & cacu distribution
				if (ppl_sim < edu_share[0] * Nsim_ppl) {
					ppl_edu = 0;
					if (i_occp0_sim_tmp == 0) {
						if (occp0_sim_tmp == 0) {
							entr_edu_0_0 += 1. / (Nsim_ppl * edu_share[0]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_0_0 += 1 / (Nsim_ppl * edu_share[0]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_0_0 += 1. / (Nsim_ppl * edu_share[0]);
						}
					}
					else if (i_occp0_sim_tmp == 1) {//want to work
						if (occp0_sim_tmp == 0) {
							entr_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_1_0 += 1. / (Nsim_ppl * edu_share[0]);
						}
					}
				}
				else if (ppl_sim > edu_share[0] * Nsim_ppl && ppl_sim < (edu_share[0] + edu_share[1]) * Nsim_ppl) {
					ppl_edu = 1;
					if (i_occp0_sim_tmp == 0) {
						if (occp0_sim_tmp == 0) {
							entr_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_0_1 += 1. / (Nsim_ppl * edu_share[1]);
						}
					}
					else if (i_occp0_sim_tmp == 1) {//want to work
						if (occp0_sim_tmp == 0) {
							entr_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_1_1 += 1. / (Nsim_ppl * edu_share[1]);
						}
					}
				}
				else {
					ppl_edu = 2;
					if (i_occp0_sim_tmp == 0) {
						if (occp0_sim_tmp == 0) {
							entr_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_0_2 += 1. / (Nsim_ppl * edu_share[2]);
						}
					}
					else if (i_occp0_sim_tmp == 1) {//want to work
						if (occp0_sim_tmp == 0) {
							entr_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
						}
						else if (occp0_sim_tmp == 1) {
							emp_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
							emp_rate += 1. / Nsim_ppl;
						}
						else if (occp0_sim_tmp == 2) {
							unemp_edu_1_2 += 1. / (Nsim_ppl * edu_share[2]);
						}
					}
				}

			}

			double tmp_a0, tmp_x0, tmp_cev;
			int tmp_z0, tmp_m0, tmp_i_HI0;
			//changed line
			ofstream file_2(workingpath_new + "sim_v18.txt");
			ave_welfare = 0.0;
			for (int ppl_sim = 0; ppl_sim < Nsim_ppl; ppl_sim++) {

				tmp_a0 = a0_sim[ppl_sim];
				tmp_x0 = x0_sim[ppl_sim];
				occp0_sim_tmp = occp0_sim[ppl_sim];

				tmp_cev = intp_2d_opt(tmp_a0, tmp_x0, occp0_sim_tmp, ppl_edu, cev);
				cev_sim[ppl_sim] = tmp_cev;

				ave_welfare += tmp_cev;

				file_2 << a0_sim[ppl_sim] << " " << x0_sim[ppl_sim] << " "
					<< a1_sim[ppl_sim] << " " << i_occp0_sim[ppl_sim] << " " << n_sim[ppl_sim] << " " << k0_sim[ppl_sim] << " " << y_sim[ppl_sim] << " "
					<< cev_sim[ppl_sim] << endl;
			}
			file_2.close();


			//calculate aggregate variables.
			r1 = (1.0 - r_decompose) * (1.0 + (asset_demand - asset_supply) / ((asset_demand + asset_supply) / 2.0)) * r0 + r_decompose * r_ben;
			w1 = (1.0 + (n_demand - n_supply) / ((n_demand + n_supply) / 2.0)) * w0;
			//cout << "7.5" << endl;

			ave_earning1 = earning_sim / Nsim_ppl;

			tau_y1 = total_lower_out / earning_wkr;// cacu need out num
			t_lumpsum1 = total_lower_out / Nsim_ppl;

			if (ind_policy == 0) {
				t_lumpsum_ben = t_lumpsum1 / ave_earning1;
			}

			if (dummy_UI == 1) {
				t_lumpsum1 = t_lumpsum_ben * ave_earning1;
			}

			agg_cfloor_transfer = agg_cfloor_transfer / Nsim_ppl;
			n_cfloor_transfer = n_cfloor_transfer / Nsim_ppl;

			a_y = asset_supply / agg_y_sim;
			k_y = asset_demand / agg_y_sim;

			//health insurance
			earning_wkr = earning_wkr / n_supply;
			earning_entr = earning_entr / entr_ratio;



			//firm dist.
			firm_size = n_demand / entr_ratio;
			firm_big = firm_big / entr_ratio;

			entr_ratio = entr_ratio / Nsim_ppl;

			gdp1 = agg_y_sim;
			ave_welfare = ave_welfare / Nsim_ppl;
			z_agg = z_agg / n_supply;

			r_path_new[i_t] = r1;
			w_path_new[i_t] = w1;
			theta_ut_path_new[i_t] = theta_ut_new;
			z_agg_path_new[i_t] = z_agg;
			rho_aver_path_new[i_t] = rho_aver_new;
		}

		//renew the path
		tol_param_path = 0.0;
		for (int i_t = 1; i_t < T - 1; i_t++) {
			r_path[i_t] = (1.0 - update_step1) * r_path_new[i_t] + update_step1 * r_path[i_t];
			w_path[i_t] = (1.0 - update_step1) * w_path_new[i_t] + update_step1 * w_path[i_t];
			theta_ut_path[i_t] = (1.0 - update_step1) * theta_ut_path_new[i_t] + update_step1 * theta_ut_path[i_t];
			z_agg_path[i_t] = (1.0 - update_step1) * z_agg_path_new[i_t] + update_step1 * z_agg_path[i_t];
			rho_aver_path[i_t] = (1.0 - update_step1) * rho_aver_path_new[i_t] + update_step1 * rho_aver_path[i_t];

			tol_param_path += abs(r_path_new[i_t] - r_path[i_t]) + abs(w_path_new[i_t] - w_path[i_t]) + abs(theta_ut_path_new[i_t] - theta_ut_path[i_t]);

			cout << "r path"<< r_path[i_t] << endl;
		}

		if (loop_trans_iter > 500) {
			break;
		}
		loop_trans_iter += 1;

		tol_param_path = tol_param_path / (T-2);

		cout << "end for tol path tol" << tol_param_path << endl;
	}while (tol_param_path > 1e-4);

	return 0;
}

//sub-routines:
void policy_to_do()
{
	solve_model();

}



void policy_exp()
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
	update_step1 = 0.975 - 0.4;
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
	update_step1 = 0.95 - 0.4;
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
	update_step1 = 0.95 - 0.4;
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

	k_tmp = pow(x0_credit * alpha / (1.0 + r_wedge) / r0 * pow(z_agg * n_tmp, gamma), 1.0 / (1.0 - alpha));

	rev_tmp2 = x0_credit * pow(k_tmp, alpha) * pow(z_agg * n_tmp, gamma);

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
	k_tmp = pow((r0 / x0_credit) * pow((z_agg * r0 * gamma) / (alpha * t_tmp), -gamma) * (1 / alpha), 1 / (alpha + gamma - 1));

	rev_tmp1 = gamma * x0_credit * pow(k_tmp, alpha) * z_agg * pow(n_tmp, gamma - 1);
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
	k_tmp = pow(k_tmp1 * pow(n_tmp * z_agg, gamma), 1.0 / (1.0 - alpha));

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
			gamma = gamma_edu[i_e];


			x_tmp = x_shk[i_x][i_e];
			//change for new question for w0
			w0_with_edu = w0;

			x0_credit = x_tmp;
			


			//w0_with_edu = edu_share[0] * w0 * (1 + edu_z[0]) + edu_share[1] * w0 * (1 + edu_z[1]) + edu_share[2] * w0 * (1 + edu_z[2]);

			T_tmp = z_agg * w0_with_edu * (1 + psi * tau) + (kappa * w0_with_edu * rho_aver * z_agg) / theta_ut;

			//T_tmp = z_agg * w0_with_edu * (1 + psi * tau) + (kappa * w0_with_edu * edu_rho[i_e] * z_agg) / theta_ut;

			k_star_tmp = pow((r0 / x_tmp) * pow((z_agg * r0 * gamma) / (alpha * T_tmp), -gamma) * (1 / alpha), 1 / (alpha + gamma - 1));

			n_star_tmp = (r0 * gamma) / (alpha * T_tmp) * k_star_tmp;

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

			y_tmp = x_tmp * pow(k_star_tmp, alpha) * pow(z_agg * n_star_tmp, gamma);
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
	//cout << "find_credit_const" << endl;
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
		fabs(theta_ut_new - theta_ut)
		) {
		return false;

	}
	return ans;
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
	ifstream fp(workingpath + "data\\Input\\CFV\\policy_functions_v17_in.txt");


	//get input
	//change for no new
	for (int i_e = 0; i_e < Ne; i_e++) {
		for (int i_a = 0; i_a < Na_in; i_a++) {
			for (int i_x = 0; i_x < Nx_in; i_x++) {
				for (int i_occp = 0; i_occp < Ni; i_occp++) {
					for (int i_occp_en = 0; i_occp_en < Ni - 1; i_occp_en++) {

						double dg0, dg1, dg2, dg3, dg4, dg5, dg6, dg7, dg8, dg9;
						fp >> dg0 >> dg1 >> dg2 >> dg3 >> dg4 >> dg5 >> dg6 >> dg7 >> dg8 >> dg9;

						//cout << dg0 << dg1 << dg2 << dg3 << dg4 << dg5 << dg6 << dg7 << dg8 << dg9 << endl;
						a_vec_in[i_a] = dg0;
						x_shk_in[i_x] = dg1;
						if (dg4 < 2.0 * a_l) {
							dg4 = 2.0 * a_l;
						}
						v_in[i_a][i_x][i_occp][i_e] = dg4;
						//opt_occp_in[i_a][i_x][i_occp][i_e] = 1;
						opt_a_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg5;
						opt_k_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg6;
						opt_n_in[i_occp][i_occp_en][i_a][i_x][i_e] = dg7;
						opt_occp_in[i_a][i_x][i_occp][i_e] = dg9;


					}
				}
			}
			cout << a_vec_in[i_a] << endl;
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
	int i_a0;
	NRlocate(a_vec, Na, x_a0, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na - 1) { i_a0 = Na - 2; }

	
	for (int i_x = 0; i_x < Nx; i_x++) {
		forNR_x_shk[i_x] = x_shk[i_x][edu_occp];
	}
	int i_x0;
	NRlocate(forNR_x_shk, Nx, x_x0, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx - 1) { i_x0 = Nx - 2; }

	double fa, fb, fc, fd, ft, fu;

	fa = policy[x_occp0][i_x_occp][i_a0][i_x0][edu_occp];
	fb = policy[x_occp0][i_x_occp][i_a0 + 1][i_x0][edu_occp];
	fc = policy[x_occp0][i_x_occp][i_a0 + 1][i_x0 + 1][edu_occp];
	fd = policy[x_occp0][i_x_occp][i_a0][i_x0 + 1][edu_occp];

	ft = (x_a0 - a_vec[i_a0]) / (a_vec[i_a0 + 1] - a_vec[i_a0]);
	if (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp] <= 0.0000001) {
		fu = (x_x0 - x_shk[i_x0][edu_occp]);
	}
	else {
		fu = (x_x0 - x_shk[i_x0][edu_occp]) / (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp]);
	}

	return (1.0 - ft) * (1.0 - fu) * fa + ft * (1.0 - fu) * fb + ft * fu * fc + (1.0 - ft) * fu * fd;
}

//change for edu dim

double intp_2d_opt(double& x_a0, double& x_x0, int& x_occp0, int& edu_occp,
	double policy[Na][Nx][Ni][Ne])
{
	int i_a0;
	NRlocate(a_vec, Na, x_a0, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na - 1) { i_a0 = Na - 2; }
	
	for (int i_x = 0; i_x < Nx; i_x++) {
		forNR_x_shk[i_x] = x_shk[i_x][edu_occp];
	}
	int i_x0;
	NRlocate(forNR_x_shk, Nx, x_x0, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx - 1) { i_x0 = Nx - 2; }

	double fa, fb, fc, fd, ft, fu;
	fa = policy[i_a0][i_x0][x_occp0][edu_occp];
	fb = policy[i_a0 + 1][i_x0][x_occp0][edu_occp];
	fc = policy[i_a0 + 1][i_x0 + 1][x_occp0][edu_occp];
	fd = policy[i_a0][i_x0 + 1][x_occp0][edu_occp];

	ft = (x_a0 - a_vec[i_a0]) / (a_vec[i_a0 + 1] - a_vec[i_a0]);
	if (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp] <= 0.0000001) {
		fu = (x_x0 - x_shk[i_x0][edu_occp]);
	}
	else {
		fu = (x_x0 - x_shk[i_x0][edu_occp]) / (x_shk[i_x0 + 1][edu_occp] - x_shk[i_x0][edu_occp]);
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
	int i_a0;
	NRlocate(a_vec_in, Na_in, x_a0, i_a0);
	if (i_a0 == -1) { i_a0 = 0; }
	if (i_a0 == Na_in - 1) { i_a0 = Na_in - 2; }

	int i_x0;
	NRlocate(x_shk_in, Nx_in, x_x0, i_x0);
	if (i_x0 == -1) { i_x0 = 0; }
	if (i_x0 == Nx_in - 1) { i_x0 = Nx_in - 2; }

	double fa, fb, fc, fd, ft, fu;

	//change for no health
	fa = policy[i_x_occp][x_occp0][i_a0][i_x0][edu_occp];
	fb = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0][edu_occp];
	fc = policy[i_x_occp][x_occp0][i_a0 + 1][i_x0 + 1][edu_occp];
	fd = policy[i_x_occp][x_occp0][i_a0][i_x0 + 1][edu_occp];

	ft = (x_a0 - a_vec_in[i_a0]) / (a_vec_in[i_a0 + 1] - a_vec_in[i_a0]);
	fu = (x_x0 - x_shk_in[i_x0]) / (x_shk_in[i_x0 + 1] - x_shk_in[i_x0]);

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
