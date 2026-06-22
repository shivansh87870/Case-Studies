"""
PURPOSE

Determine whether the conversion difference
between experiment groups is statistically
significant.
"""

import numpy as np
from scipy.stats import chi2_contingency

observed_data = np.array([
    [300,9700],
    [342,9658]
])

chi2_stat,\
p_value,\
degrees_of_freedom,\
expected_values = (
    chi2_contingency(observed_data)
)

print(
    f"P-value = {p_value:.4f}"
)

if p_value < 0.05:

    print(
        "Statistically significant."
    )

else:

    print(
        "Difference could be random."
    )
