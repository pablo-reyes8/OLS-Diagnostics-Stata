*****************************************************
*  Regression Assumption Diagnostics & Corrections 
*  A Comprehensive Stata Script  
*  
*  "Testing and Remediating Violations of  
*   Classical Linear Regression Assumptions"  
*  
*  Author: Pablo Reyes  
*  Date: May 2025  
*****************************************************


// Before we start // 

clear all
set more off

// Import the data // 

import excel "C:\Users\alejo\OneDrive\Escritorio\Universidaad\5 semestre\Econometria\lawsch85.xlsx", sheet("Sheet1") firstrow


*****************************************************
* 0. Glossary of Key Terms
* ---------------------------------------------------
* A quick reference for key concepts and abbreviations
*****************************************************

* **Biased estimator (β̂ biased):**  
*   An estimator whose expected value does not equal  
*   the true parameter (E[β̂] ≠ β).

* **Efficient estimator:**  
*   Among all unbiased estimators, has the smallest  
*   variance (i.e., lowest uncertainty).

* **Residual (û or resid):**  
*   The difference between observed and fitted values:  
*     resid_i = y_i – ŷ_i.

* **Heteroskedasticity:**  
*   Non-constant variance of residuals across X;  
*   violates homoskedasticity assumption.

* **Autocorrelation:**  
*   Correlation of residuals across observations;  
*   common in time-series or spatial data.

* **Multicollinearity:**  
*   High linear correlation among regressors; measured  
*   by VIF (Variance Inflation Factor).

* **VIF (Variance Inflation Factor):**  
*   VIF_i = 1/(1–R²_i) from regressing X_i on other X's;  
*   VIF > 5 indicates problematic collinearity.

* **Endogeneity:**  
*   When a regressor correlates with the error term  
*   (Cov(X,u) ≠ 0); leads to biased, inconsistent estimates.

* **Outlier:**  
*   Observation with an unusually large residual  
*   (|rstudent| > 2).

* **Influential point:**  
*   Observation that substantially alters estimates;  
*   flagged by high leverage or Cook's distance.

* **BLUE:** Best Linear Unbiased Estimator —  
*   OLS estimators are BLUE if Gauss–Markov assumptions hold.

*****************************************************
* End of Glossary
*****************************************************









*****************************************************
* 1. Model Specification
* ---------------------------------------------------
* Purpose: Ensure the linear regression includes the
*          correct predictors and functional form.
*****************************************************

*── What does "misspecification" mean? ─────────────────
* When we say a model is "misspecified," it means
*   – The wrong set of independent variables was chosen, or
*   – The functional form (level vs. log, quadratic, etc.)
*     does not match the true relationship.
*
*── What problems can it cause? ────────────────────────
*   • Biased parameter estimates
*   • Serial correlation (autocorrelation)
*   • Heteroskedasticity
*   • Endogeneity
*   • Multicollinearity
*
*── Remedies ────────────────────────────────────────────
* 1) Try alternative transformations of Y and X:
*    • level–level, log–level, level–log, log–log
generate lnGPA       = ln(GPA)
generate lnsalary    = ln(salary)

* level–level
regress salary   GPA
* log–level
regress lnSalary GPA
* level–log
regress salary   lnGPA
* log–log
regress lnSalary lnGPA

* 2) Add additional relevant predictors:
regress salary GPA LSAT age lcost

* 3) Include quadratic terms for non-linear effects:
generate LSAT2 = LSAT^2
regress salary GPA LSAT LSAT2 age lcost

* 4) Visually inspect scatterplots for non-linear patterns:
*    Example: variable "cost" vs. "salary"
twoway (scatter salary cost) ///
       (lfit   salary cost), ///
       title("Salary vs. Cost: Check for Non-Linearity")

*── How to detect misspecification? ────────────────────
* Use the Ramsey RESET test to check for omitted
* non-linear combinations of fitted values.

* Step 1: Estimate the base model
regress salary GPA LSAT age lcost

* Step 2: Run RESET
estat ovtest
*   H0: No omitted variables or misspecification
*       (we want p-value > 0.05 or 0.10 to accept H0)
*   H1: Model is misspecified

*── Manual implementation of RESET ─────────────────────
* 1) Obtain fitted values
predict yhat, xb

* 2) Create powers of fitted values
generate yhat2 = yhat^2
generate yhat3 = yhat^3

* 3) Re-estimate including yhat^2 and yhat^3
regress salary GPA LSAT age lcost yhat2 yhat3

* 4) Joint F-test for coefficients on yhat2 & yhat3
test yhat2 yhat3
*   H0: coefficients = 0 (model correctly specified)
*   Reject H0 → evidence of misspecification

*****************************************************
* End of Section 1
*****************************************************








*****************************************************
* 2. Heteroskedasticity
* ---------------------------------------------------
* Purpose: Detect and correct non-constant error variance
*****************************************************

*── What is heteroskedasticity? ───────────────────────
* When Var(u_i) ≠ σ² for all observations, the dispersion
* of the residuals changes across levels of X.
* Common causes:
*   • Learning or experience effects over time
*   • Income–savings relationships (higher income ⇒ more varied savings)
*   • Presence of outliers or grouped data
*
*── Consequences ───────────────────────────────────────
*   • OLS estimates remain unbiased but are no longer efficient
*   • Standard errors are biased → invalid t-tests & confidence intervals
*****************************************************

*── Visual diagnostic ─────────────────────────────────
* Plot residuals vs. fitted values
regress salary GPA LSAT age lcost
predict yhat, xb
predict resid, residuals
twoway scatter resid yhat, ///
    title("Residuals vs. Fitted Values") ///
    xlabel(, grid) ylabel(, grid)

*****************************************************
* Detection Tests
*****************************************************

* 1) Breusch–Pagan / Cook–Weisberg test
regress salary GPA LSAT age lcost
estat hettest           // default uses yhat
estat hettest, rhs      // uses X's directly
*  H0: homoskedasticity (constant variance)
*  H1: heteroskedasticity

* Manual Breusch–Pagan steps
predict resid, residuals
generate resid2 = resid^2
regress resid2 GPA LSAT age lcost
*  H0: no relationship between u² and predictors → homoskedasticity

* 2) White's general test
regress salary GPA LSAT age lcost
estat imtest, white
*  H0: homoskedasticity
*  H1: heteroskedasticity (includes X² and cross-terms)

*****************************************************
* Remedies for Heteroskedasticity
*****************************************************

* a) Robust (Huber-White) standard errors
regress salary GPA LSAT age lcost, vce(robust)

* b) Explicit heteroskedastic model via hetregress
hetregress salary GPA LSAT age lcost, vce(robust)

* c) Feasible GLS (two-step)
hetregress salary GPA LSAT age lcost, ///
    twostep het(GPA LSAT age lcost)

*****************************************************
* End of Section 2
*****************************************************










*****************************************************
* 3. Multicollinearity
* ---------------------------------------------------
* Purpose: Diagnose and address high correlation 
*          among regressors in a linear model.
*****************************************************

*── What is multicollinearity? ───────────────────────
* Occurs when two or more independent variables are
* highly linearly related, making it hard to isolate
* individual effects.

*── Consequences ─────────────────────────────────────
*   • Inflated standard errors → wider CIs
*   • Insignificant t‐statistics despite high R²
*   • Coefficients and SEs become sensitive to small
*     data changes
*   • Difficult interpretation of individual effects

*****************************************************
* Detection: Variance Inflation Factor (VIF)
*****************************************************

* Step 1: Fit the base model
regress salary GPA LSAT age lcost

* Step 2: Compute VIFs
estat vif
*  Rule of thumb: VIF < 5 → low multicollinearity

*── VIF theory ───────────────────────────────────────
* For each regressor x_i:
*   • Regress x_i on all other X's → obtain R²_i
*   • VIF_i = 1 / (1 – R²_i)
* Measures how much var(β_i) is inflated by collinearity

*****************************************************
* Remedies for Multicollinearity
*****************************************************

* a) Drop one of the highly correlated variables
*    (e.g., if GPA and LSAT correlate strongly, remove one)
*
* b) Transform variables (e.g., center or standardize)
*
* c) Combine correlated variables into a single index
*    generate academic_index = (GPA + LSAT)/2
*
* d) Collect more data or use a different dataset
*
* e) If the goal is prediction, multicollinearity is less
*    problematic—focus on out‐of‐sample performance

* Note: Polynomial terms inherently correlate with their
*       base variable (e.g., x and x²). VIF here is expected.

*****************************************************
* End of Section 3
*****************************************************











*****************************************************
* 4. Spatial Autocorrelation
* ---------------------------------------------------
* Purpose: Test for spatial dependence among residuals
*****************************************************

*── What is spatial autocorrelation? ───────────────────
* Observations close in space influence each other,
* violating the assumption of independent residuals.
* Example: regions like Armenia and Pereira may show
* similar behavior due to geographic proximity.

*── Consequences ─────────────────────────────────────
*   • Biased and inefficient estimates
*   • Residual heteroskedasticity
*   • Invalid inference (t- and F-tests)

*****************************************************
* Detection: Moran's I Test on OLS Residuals
*****************************************************

* 1) Estimate the base OLS model
regress salary GPA LSAT age lcost

* 2) (If not already defined) load or create your spatial
*    weights matrix "W" (e.g., contiguity or distance)
*    Example: define contiguity matrix from shapefile
*    spmat from(shapefile.shp), id(idvar) contiguity(W)

* 3) Test global Moran's I on residuals
*    – "errorlag(W)" if using a spatial-error model;
*      for pure OLS residuals, omit the option
estat moran, errorlag(W)
*  H0: residuals are i.i.d. (no spatial autocorrelation)
*  H1: residuals exhibit spatial autocorrelation

*****************************************************
* End of Section 4
*****************************************************











*****************************************************
* 5. Endogeneity
* ---------------------------------------------------
* Purpose: Diagnose and correct correlation between
*          regressors and the error term
*****************************************************

*── What is endogeneity? ─────────────────────────────
* Occurs when an explanatory variable X is correlated
* with the error term u (Cov(X,u) ≠ 0), violating
* the OLS assumption of exogeneity.
*
*── Consequences ─────────────────────────────────────
*   • Biased and inconsistent OLS estimates
*   • Invalid inference and interpretation

*****************************************************
* Detection & Identification
*****************************************************

* 1) Initial OLS (robust SEs) for baseline comparison
regress salary GPA libvol age lcost, vce(robust)

* 2) Instrumental Variable (IV) approach
*    – Z must satisfy: Cov(Z,u) = 0 and Cov(Z,X) ≠ 0
*    – Example: suspect GPA endogenous; use LSAT as IV

* 2a) First-stage regression: X on Z and exogenous controls
regress GPA libvol age lcost LSAT
*  H0: β_LSAT = 0 (LSAT is not a valid instrument)
*  Reject H0 → LSAT is correlated with GPA (valid IV)

* 2b) Two-stage least squares (2SLS)
ivregress 2sls salary libvol age lcost (GPA = LSAT)
*  – Estimates consistent if instrument valid

* 2c) Durbin (1954) test for endogeneity
estat endog
*  H0: GPA is exogenous (do not reject → stick with OLS)
*  H1: GPA is endogenous

* 3) Wu–Hausman "long" test (for large samples, n > 100)
*  3a) First-stage as above, then save residuals
regress GPA libvol age lcost LSAT
predict resid5, residuals

*  3b) Augmented regression including residuals
regress salary GPA libvol age lcost resid5, vce(robust)
*  H0: coefficient on resid5 = 0 (exogeneity of GPA)
*  Reject H0 → evidence of endogeneity

* 4) Overidentification test (if using multiple IVs)
*    Ensures instruments are valid when count(IV) > count(endog)
estat overid
*  H0: instruments are valid (no evidence of overidentification)
*  H1: invalid instruments or too many instruments

*****************************************************
* Remedies for Endogeneity
*****************************************************
*  a) Use valid instruments (IV/2SLS)
*  b) Find proxy variables
*  c) Model the endogeneity (e.g., control functions)
*  d) If no endogeneity → OLS is optimal

*****************************************************
* End of Section 5
*****************************************************










*****************************************************
* 6. Normality of Residuals
* ---------------------------------------------------
* Purpose: Verify that the OLS residuals are 
*          approximately normally distributed.
*****************************************************

* 1) Estimate the base model and obtain residuals
regress salary GPA LSAT age lcost
drop resid
predict resid, residuals

* 2) Histogram with overlaid normal density
histogram resid, normal ///
    title("Histogram of Residuals with Normal Curve") ///
    xlabel(, grid) ylabel(, grid)

* 3) Q-Q plot for visual assessment
qnorm resid ///
    title("Q-Q Plot of Residuals")

* 4) Shapiro–Wilk test (recommended for n < 2000)
swilk resid
*  H0: residuals are normally distributed

* 5) Skewness/Kurtosis (Jarque–Bera) test
sktest resid
*  H0: skewness = 0 and kurtosis = 3

*****************************************************
* Remedies if Normality is Violated
*****************************************************
* • Transform dependent variable (e.g., log(salary))
*   generate lnSalary = ln(salary)
*   regress lnSalary GPA LSAT age lcost, vce(robust)
*
* • Use bootstrap standard errors for inference
*   bootstrap, reps(1000) seed(12345): ///
*       regress salary GPA LSAT age lcost
*****************************************************










*****************************************************
* 7. Outliers & Influential Observations
* ---------------------------------------------------
* Purpose: Identify data points that unduly influence
*          regression estimates.
*****************************************************

* 1) Fit the base model
regress salary GPA LSAT age lcost

* 2) Leverage (hat values)
predict hat, hat
*    • Rule of thumb: leverage > 2*(k+1)/n → high leverage

* 3) Studentized residuals
predict rstudent, rstudent
*    • |rstudent| > 2 → potential outlier

* 4) Cook's distance
predict cooksd, cooksd
*    • cooksd > 4/(n - k - 1) → influential observation

* 5) DFBETAs
predict dfbeta*, dfbeta
*    • |DFBETA_i| > 2/sqrt(n) → observation has large influence
*      on coefficient i

* 6) List flagged observations (adjust thresholds as needed)
list salary GPA LSAT age lcost hat rstudent cooksd if ///
     hat       > 2*(e(df_m)+1)/e(N) | ///
     abs(rstudent) > 2               | ///
     cooksd    > 4/(e(N)-e(df_m)-1)

* 7) Influence plots
*    • Added‐variable plots to spot influential points
avplots, mlabel(_n)
*    • Global influence index plot
estat influence

*****************************************************
* End of Section 7
*****************************************************


*This script walks you through the full suite of diagnostic checks for a cross-sectional OLS model—covering specification, heteroskedasticity, multicollinearity, spatial dependence, endogeneity, residual normality, and outlier/influence analysis. By systematically testing and, where necessary, remedying each assumption, you ensure that your coefficient estimates are unbiased, efficient, and that your inference (standard errors, t-tests, confidence intervals) remains valid. Incorporating these diagnostics into every model run will greatly enhance both the credibility and interpretability of your regression results. Always review flagged issues (e.g. significant RESET or heteroskedasticity tests, high VIFs, influential points, or evidence of endogeneity) and apply the corrective actions outlined before drawing policy or substantive conclusions.*
