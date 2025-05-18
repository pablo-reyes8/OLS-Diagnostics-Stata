# OLS-Diagnostics-Stata

**Comprehensive Stata do-file for testing and correcting violations of classical OLS assumptions**

---

## Description

This repository contains a single Stata do-file that implements a full suite of diagnostic tests and remedies for violations of the classical linear regression assumptions in cross-sectional data:

1. **Model Specification**  
2. **Heteroskedasticity**  
3. **Multicollinearity**  
4. **Spatial Autocorrelation**  
5. **Endogeneity**  
6. **Residual Normality**  
7. **Outlier & Influence Detection**
## Usage

1. Clone this repository:  
   ```bash
   git clone https://github.com/your-username/OLS-Diagnostics-Stata.git
   ```
2. Open Stata and run the do-file
3. Review the log output and graphs to identify any assumption violations.
4. Apply the suggested corrective commands included in each section if needed.

---

## File Structure

```plaintext
.
├── Regression Assumptions.do   # Main Stata script with all tests & remedies
├── Lawsch85.xlsx               # Dataset used to run the script
└── README.md                   # Project documentation
```

## Contribution

Feel free to open issues or submit pull requests to add more diagnostics, improve formatting, or support panel/time-series extensions.

