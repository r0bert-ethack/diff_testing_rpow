import sys
import math
from decimal import Decimal, getcontext
from eth_abi import encode

def rpow(integerPart, decimalPart, exponent, scalar):
    integer = integerPart + decimalPart

    try:
        result = (integer ** Decimal(exponent))

        # Convert result to string
        result_str = format(result, 'f')

        # Split integer and decimal parts
        if '.' in result_str:
            integer_part, decimal_part = result_str.split('.')
        else:
            integer_part = result_str
            decimal_part = '0'

        digits = int(math.log10(scalar))

        # Ensure the decimal part has exactly 27 digits
        decimal_part = decimal_part[:digits].ljust((digits), '0')

        # Combine integer and formatted decimal part
        formatted_result = integer_part + decimal_part
        
        # Convert to integer
        result_int = int(formatted_result)
        result_str = str(result_int).replace('.', '')
        
        # Convert back to integer
        resultTrimmed = int(result_str)
    except OverflowError:
        return int(0)
    return resultTrimmed

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 5:
        print("Usage: python3 RPow.py <integerPart> <decimalPart> <exponent> <scalar>")
        return
    
    try:
        getcontext().prec = 50

        # Get the command line arguments
        integerPart = Decimal(sys.argv[1])
        decimalPart = Decimal(sys.argv[2]) / Decimal(sys.argv[4])
        exponent = int(sys.argv[3])
        scalar = int(sys.argv[4])
        
        # Calculate the nth power
        result = rpow(integerPart, decimalPart, exponent, scalar)

        if (result >= (2 ** 256)):
            enc = encode(['uint256'], [int(0)])
            print("0x" + enc.hex())
        else:
            enc = encode(['uint256'], [result])
            print("0x" + enc.hex())
    except ValueError:
        enc = encode(['uint256'], [int(0)])
        print("0x" + enc.hex())

if __name__ == "__main__":
    main()
