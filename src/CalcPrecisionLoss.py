from decimal import Decimal, getcontext
import sys
from eth_abi import encode

def calculate_precision_loss(original_value, new_value):
    # Set the precision to a sufficiently high value
    getcontext().prec = 50

    # Convert input values to high precision Decimal
    original = Decimal(original_value)
    new = Decimal(new_value)

    # Calculate the absolute difference
    difference = abs(original - new)

    if(original > new):
        if(new == 0):
            precision_loss = 10000
        else:
            precision_loss = (difference * 10000) / new
    else:
        if(original == 0):
            precision_loss = 10000
        else:
            precision_loss = (difference * 10000) / original

    return precision_loss

if __name__ == "__main__":
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python3 CalcPrecisionLoss.py <originalValue> <newValue>")
        sys.exit(1)

    original_value = sys.argv[1]
    new_value = sys.argv[2]

    # Calculate precision loss
    precision_loss = calculate_precision_loss(original_value, new_value)

    # Print the result
    enc = encode(['uint256'], [int(precision_loss)])
    print("0x" + enc.hex())
