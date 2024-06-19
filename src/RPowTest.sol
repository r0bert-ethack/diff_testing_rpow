import "forge-std/Test.sol";
import "./RPow.sol";

/*
    forge test -vvvv --match-contract RPowTest --show-progress
    forge test -vvvv --match-contract RPowTest --match-test test_RPow --show-progress
    forge test -vvvv --match-contract RPowTest --match-test test_RealCase_RPow --show-progress
*/

contract RPowTest is Test{

    event DebugUint(string a, uint256 b);
    event DebugStr(string a, string b);
    event DebugBool(string a, bool b);
    
    // function rpow(uint256 x, uint256 n, uint256 scalar) internal pure returns (uint256 z, bool overflow) 
    function test_RPow(uint256 x, uint256 n, uint256 scalar) public {
        /*
            scalar
            min: 10 ^ 1
            max: 10 ^ 30
        */
        scalar = bound(scalar, 1, 30);
        scalar = 10 ** scalar;
        /*
            n
            min: 1
            max: 10 years
        */
        n = bound(n, 1, 365 days * 10);
        /*
            x
            min: 0
            max: 65535 = type(uint16).max
            Note: The value is this low as we want that most of the runs to not overflow
        */
        x = bound(x, 0, type(uint16).max);
        emit DebugUint("x ...................................................................", x);
        emit DebugUint("n ...................................................................", n);
        emit DebugUint("scalar ..............................................................", scalar);
        (uint256 returned, bool overflow) = RPow.rpow(x, n, scalar);
        emit DebugBool("Library overflow ....................................................", overflow);
        emit DebugUint("Library result ......................................................", returned);
        if(overflow){
            return;
        }
        string[] memory cmds = new string[](6);
        cmds[0] = "python3";
        cmds[1] = "src/RPow.py";
        cmds[2] = vm.toString(x / scalar);
        emit DebugUint("intPart .............................................................", x / scalar);
        cmds[3] = vm.toString(x % scalar);
        emit DebugUint("decimalPart .........................................................", x % scalar);
        cmds[4] = vm.toString(n);
        cmds[5] = vm.toString(scalar);
        bytes memory result = vm.ffi(cmds);
        uint256 res = abi.decode(result, (uint256));
        emit DebugUint("Python script result ................................................", res);
        uint256 precisionLoss;
        if(returned != 0){
            // precisionLoss = _calculatePrecisionLoss(returned, res);
            precisionLoss = _calculatePrecisionLossPython(returned, res, scalar);
        }
        // Used to handle the case where the result is a very small number
        uint256 subsTractionDiff;
        if(res > returned){
            subsTractionDiff = res - returned;
        }
        else{
            subsTractionDiff = returned - res;
        }
        emit DebugUint("PrecisionLoss .......................................................", precisionLoss);
        /* 
            OK IF:
            1. Python script and Solidity library results are equal
            2. Python script and Solidity library results difference does not exceed the 0.1%
            3. Python script and Solidity library substraction result is not higher than 1
        */
        assert((res == returned) || (precisionLoss < 1e2) || (subsTractionDiff < 2)); // 1e2 = 0.1% of precision loss
    }

    // RPow.rpow(interestRate + 1e27, deltaT, 1e27);
    function test_RealCase_RPow(uint256 x, uint256 n) public {
        /*
            scalar = 1e27
        */
        uint256 scalar = 1e27;
        /*
            n
            min: 1
            max: 2 years
        */
        n = bound(n, 1, 365 days * 2);
        /*
            x
            min: 0
            max: 1_000000291867278914945094175
        */
        x = bound(x, 0, 291867278914945094175);
        x = x + 1e27;
        emit DebugUint("x ...................................................................", x);
        emit DebugUint("n ...................................................................", n);
        emit DebugUint("scalar ..............................................................", scalar);
        (uint256 returned, bool overflow) = RPow.rpow(x, n, scalar);
        emit DebugBool("Library overflow ....................................................", overflow);
        emit DebugUint("Library result ......................................................", returned);
        if(overflow){
            return;
        }
        string[] memory cmds = new string[](6);
        cmds[0] = "python3";
        cmds[1] = "src/RPow.py";
        cmds[2] = vm.toString(x / scalar);
        emit DebugUint("intPart .............................................................", x / scalar);
        cmds[3] = vm.toString(x % scalar);
        emit DebugUint("decimalPart .........................................................", x % scalar);
        cmds[4] = vm.toString(n);
        cmds[5] = vm.toString(scalar);
        bytes memory result = vm.ffi(cmds);
        uint256 res = abi.decode(result, (uint256));
        emit DebugUint("Python script result ................................................", res);
        uint256 precisionLoss;
        if(returned != 0){
            // precisionLoss = _calculatePrecisionLoss(returned, res);
            precisionLoss = _calculatePrecisionLossPython(returned, res, scalar);
        }
        // Used to handle the case where the result is a very small number
        uint256 subsTractionDiff;
        if(res > returned){
            subsTractionDiff = res - returned;
        }
        else{
            subsTractionDiff = returned - res;
        }
        emit DebugUint("PrecisionLoss .......................................................", precisionLoss);
        /* 
            OK IF:
            1. Python script and Solidity library results are equal
            2. Python script and Solidity library results difference does not exceed the 0.1%
        */
        assert((res == returned) || (precisionLoss < 1e2)); // 1e2 = 0.1% of precision loss
    }

    /*
        Relative error formula: 
            relativeError = (|newValue - originalValue| / originalValue) * 100
    */
    function _calculatePrecisionLoss(uint256 originalValue, uint256 newValue) internal pure returns (uint256) {
        // Calculate the absolute difference
        uint256 difference;
        uint256 precisionLoss;
        if (originalValue > newValue) {
            difference = originalValue - newValue;
            precisionLoss = (difference * 1e5) / newValue;
        } else {
            difference = newValue - originalValue;
            precisionLoss = (difference * 1e5) / originalValue;
        }
        return precisionLoss; // The result is in basis points (1% = 1e3)
    }

    /*
        Relative error formula: 
            relativeError = (|newValue - originalValue| / originalValue) * 100
    */
    function _calculatePrecisionLossPython(uint256 original, uint256 newValue, uint256 scalar) internal returns (uint256) {
        string[] memory cmds = new string[](4);
        cmds[0] = "python3";
        cmds[1] = "src/CalcPrecisionLoss.py";
        cmds[2] = string.concat(vm.toString(original / scalar), ".", vm.toString(original % scalar));
        emit DebugStr("original .............................................................", cmds[2]);
        cmds[3] = string.concat(vm.toString(newValue / scalar), ".", vm.toString(newValue % scalar));
        emit DebugStr("decimalPart ..........................................................", cmds[3]);
        bytes memory result = vm.ffi(cmds);
        uint256 resPrecLoss = abi.decode(result, (uint256));
        emit DebugUint("Python script prec. loss ............................................", resPrecLoss);
        return resPrecLoss;
    }
}