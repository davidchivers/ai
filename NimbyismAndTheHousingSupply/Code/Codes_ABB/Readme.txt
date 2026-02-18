README file


Codes for Arellano, Blundell and Bonhomme (2016), "Earnings and Consumption Dynamics: A Nonlinear Panel Data Framework"
to appear in Econometrica

Let us know if you experience any difficulty with the files (contact: sbonhomme@uchicago.edu) 


Data

The sample from the PSID is constructed using first_stage_regs.do. It takes data.dta as input and uses select.do 
first_stage_regsmalewages.do constructs the sample 

The Norwegian earnings data is not publicly available, so we cannot provide the sample we used in the folder. 
It is described in Appendix C2 of the paper. 
Contact person for the Norwegian data at Statistics Norway: Magne Mogstad, mogstad@uchicago.edu 


Earnings

Code_earnings_est.m estimates the earnings model. Produces data_hermite2.mat, included in the folder. 
Uses the functions wqregk_e0_age, wqregk_pt_age and wqregk_eps_age 

Code_earnings_fit.m simulates the earnings model and produces Figures 1, 2abd, 3, 4 in the paper
and Figures S1 to S8. It was also used to produce the Figures on the Norwegian sample, in particular S17 to S19. 

Code_canonical_model_est_and_fit.m estimates and reports the results of the canonical earnings and consumption model
It produces Figure 2c. It uses the functions covariance_cm and covariance_cm_consumption_twostep


Consumption

Code_consumption_est.m estimates the consumption model. Produces data_hermite_cons2.mat, included in the folder.

Code_consumption_fit.m simulates the consumption model and produces Figures 5 and 6 in the paper
and Figures S20ab and S21a.


Bootstrap

Code_earnings_nonparametric_boostrap.m, Code_earnings_nonparametric_boostrap_fit.m, Code_earnings_parametric_boostrap.m 
and Code_earnings_parametric_boostrap_fit.m estimate the bootstrap results for earnings and produce Figures S9 to S14

Code_consumption_nonparametric_boostrap.m, Code_consumption_nonparametric_boostrap_fit.m, Code_consumption_parametric_boostrap.m 
and Code_consumption_parametric_boostrap_fit.m estimate the bootstrap results for consumption and produce Figures S22 and S23

Note: the bootstrap takes time


Results with unobserved heterogeneity

Code_earnings_est_FE.m estimates the earnings model with unobserved heterogeneity. It produces data_hermite_FE.mat, included in the folder. 
It uses the functions wqregk_zeta_age, wqregk_e0_age_FE, wqregk_pt_age, and wqregk_eps_age_FE

Code_earnings_fit_FE.m simulates the earnings model with unobserved heterogeneity. It produces Figure S15.

Code_consumption_est_FE_alternative_normalization.m estimates the consumption model with unosberved heterogeneity. 
It produces data_hermite_cons_FE_newnorm.mat, included in the folder.

Code_consumption_fit_FE.m simulates the consumption model with unobserved heterogeneity. It produces Figures S20c, S21b, S24 and S25.
 

Impulse responses

Code_IR_cons.m simulates impulse responses for earnings and consumption, for linear and nonlinear assets rules.
It produces Figures 7 and 8 in the paper, and Figure S31.

Code_IR_cons_by_assets.m simulates impulse responses for earnings and consumption for old and young, by initial assets,
for linear and nonlinear assets rules. It produces Figure 9 in the paper, and Figure S34 (top).

Code_canonical_model_IR.m simulates impulse responses based on the canonical linear model of earnings and consumption. 
It produces the bottom graphs in Figures 7 and 8.

Code_IR_cons_nonparametric_bootstrap.m and Code_IR_cons_nonparametric_bootstrap_fit.m produce the bootstrapped confidence bands
for impulse responses in Figures S26 to S29. 

Code_IR_cons_FE.m produces impulse responses in the models with unobserved heterogeneity in consumption.
It produces Figures S30 and S32.

Code_IR_cons_FE_by_assets.m produces impulse responses in the models with unobserved heterogeneity in consumption,
for households of different ages and initial assets.
It produces Figures S33 and S34 bottom.


Simulated model

Code_simulated_model.m processes the results of the simulation of the life-cycle model of consumption and saving.
It uses nl_nbl.mat, nl_zbl.mat, rw_nbl.mat, rw_zbl.mat, nbl.mat, and zbl.mat, all included in the folder.
Those files are constructed by the R codes located in \Simulations\Calibrated (including a readme file)
It produces Figures S35 and S36.

Code_simu_nonlinear.m and Code_simu_nonlinear_cons.m produce the graphs in Figure S37. 
The R codes used to construct the required files are located in \Simulations\Estimated (including a readme file)


 