// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TickBitmap.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-periphery/contracts/libraries/BitMath.sol";





/*

Exiting a position

We need to deploy a simple smart contract that wraps around Uniswap V3's LP exiting function and trigger this function when the above monitoring logic is executed. The output of this should result in the wallet having the LP tokens back with the position fuly exited.

The smart contract should also have a function that wraps around Uniswap V3's LP providing function and trigger this function when the above monitoring logic is executed. The output of this should result in the wallet having the LP tokens back with the position fuly exited.

The function that we need to call is exitPosition. It takes a single parameter, which is the position ID.

The position ID is the hash of the pool ID, the tick lower and the tick upper. It is a 32 bytes value.

The pool ID is the hash of the token0 address and the token1 address. It is a 32 bytes value.

The tick lower and the tick upper are 32 bytes values.

The position ID is a 96 bytes value.

When the loss crosses a threshold (like say 50%), we need to trigger the recovery process.

The recovery process is to exit the position and provide liquidity again in the same range. This will reset the price at which we provided liquidity and we will be able to start the process again.



*/

contract ExitPosition {
	INonfungiblePositionManager public immutable nonfungiblePositionManager;
	ISwapRouter public immutable swapRouter;

	constructor(
		address _nonfungiblePositionManager,
		address _swapRouter
	) {
		nonfungiblePositionManager = INonfungiblePositionManager(
			_nonfungiblePositionManager
		);
		swapRouter = ISwapRouter(_swapRouter);
	}

	function exitPosition(uint256 _positionId) external {

		nonfungiblePositionManager.decreaseLiquidity(
			INonfungiblePositionManager.DecreaseLiquidityParams({
				// The position ID
				// The position ID is the hash of the pool ID, the tick lower and the tick upper. It is a 32 bytes value.
				// The pool ID is the hash of the token0 address and the token1 address. It is a 32 bytes value.
				// The tick lower and the tick upper are 32 bytes values.
				// The position ID is a 96 bytes value.
				positionId: _positionId,
				// The amount of liquidity to decrease
				liquidity: 0,
				// The amount of token0 to receive
				amount0Min: 0,
				// The amount of token1 to receive
				amount1Min: 0,
				// The deadline for the transaction
				deadline: block.timestamp
			})
		);


	}





	function providePosition(
		address _token0,
		address _token1,
		uint24 _fee,
		int24 _tickLower,
		int24 _tickUpper,
		uint128 _amount0Desired,
		uint128 _amount1Desired,
		uint128 _amount0Min,
		uint128 _amount1Min,
		uint256 _deadline
	) external {
		nonfungiblePositionManager.mint(
			INonfungiblePositionManager.MintParams({
				token0: _token0,
				token1: _token1,
				fee: _fee,
				tickLower: _tickLower,
				tickUpper: _tickUpper,
				amount0Desired: _amount0Desired,
				amount1Desired: _amount1Desired,
				amount0Min: _amount0Min,
				amount1Min: _amount1Min,
				recipient: address(this),
				deadline: _deadline
			})
		);
	}

	function swapExactInputSingle(
		address _tokenIn,
		address _tokenOut,
		uint24 _fee,
		uint256 _amountIn,
		uint256 _amountOutMinimum,
		uint160 _sqrtPriceLimitX96
	) external {
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
			.ExactInputSingleParams({
				tokenIn: _tokenIn,
				tokenOut: _tokenOut,
				fee: _fee,
				amountIn: _amountIn,
				amountOutMinimum: _amountOutMinimum,
				sqrtPriceLimitX96: _sqrtPriceLimitX96
			});

		swapRouter.exactInputSingle(params);
	}

	function swapExactOutputSingle(
		address _tokenIn,
		address _tokenOut,
		uint24 _fee,
		uint256 _amountOut,
		uint256 _amountInMaximum,
		uint160 _sqrtPriceLimitX96
	) external {
		ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
			.ExactOutputSingleParams({
				tokenIn: _tokenIn,
				tokenOut: _tokenOut,
				fee: _fee,
				amountOut: _amountOut,
				amountInMaximum: _amountInMaximum,
				sqrtPriceLimitX96: _sqrtPriceLimitX96
			});

		

		swapRouter.exactOutputSingle(params);
	}

	

	function swapExactInput(
		ISwapRouter.ExactInputParams memory _params
	) external {
		swapRouter.exactInput(_params);
	}

	function swapExactOutput(
		ISwapRouter.ExactOutputParams memory _params
	) external {
		swapRouter.exactOutput(_params);
	}

	function swapCallback(
		uint256 _amount0Delta,
		uint256 _amount1Delta,
		bytes calldata _data
	) external {
		// do nothing
	}

	function collect(
		uint256 _positionId,
		address _recipient,
		uint128 _amount0Max,
		uint128 _amount1Max
	) external {
		nonfungiblePositionManager.collect(
			INonfungiblePositionManager.CollectParams({
				positionId: _positionId,
				recipient: _recipient,
				amount0Max: _amount0Max,
				amount1Max: _amount1Max
			})
		);
	}

	function burn(uint256 _positionId) external {
		nonfungiblePositionManager.burn(_positionId);
	}

	function increaseLiquidity(
		INonfungiblePositionManager.IncreaseLiquidityParams memory _params
	) external {
		nonfungiblePositionManager.increaseLiquidity(_params);
	}

	function decreaseLiquidity(
		INonfungiblePositionManager.DecreaseLiquidityParams memory _params
	) external {
		nonfungiblePositionManager.decreaseLiquidity(_params);
	}

	function collectProtocol(
		address _token0,
		address _token1,
		uint128 _amount0Requested,
		uint128 _amount1Requested
	) external {
		nonfungiblePositionManager.collectProtocol(
			_token0,
			_token1,
			_amount0Requested,
			_amount1Requested
		);
	}

	function setFeeProtocol(uint8 _feeProtocol0, uint8 _feeProtocol1) external {
		nonfungiblePositionManager.setFeeProtocol(_feeProtocol0, _feeProtocol1);
	}

	function setFeeGovernance(uint8 _feeGovernance0, uint8 _feeGovernance1)
		external
	{
		nonfungiblePositionManager.setFeeGovernance(
			_feeGovernance0,
			_feeGovernance1
		);
	}

	function setFeeTo(address _feeTo) external {
		nonfungiblePositionManager.setFeeTo(_feeTo);
	}

	function setFeeToSetter(address _feeToSetter) external {
		nonfungiblePositionManager.setFeeToSetter(_feeToSetter);
	}

	function setProtocolFeeMultiplier(uint16 _protocolFeeMultiplier) external {
		nonfungiblePositionManager.setProtocolFeeMultiplier(_protocolFeeMultiplier);
	}

	function setDefaultFeeProtocol(uint8 _feeProtocol0, uint8 _feeProtocol1)
		external
	{
		nonfungiblePositionManager.setDefaultFeeProtocol(
			_feeProtocol0,
			_feeProtocol1
		);
	}

	function setDefaultFeeGovernance(uint8 _feeGovernance0, uint8 _feeGovernance1)
		external
	{
		nonfungiblePositionManager.setDefaultFeeGovernance(
			_feeGovernance0,
			_feeGovernance1
		);
	}

	function setDefaultProtocolFeeMultiplier(uint16 _protocolFeeMultiplier)
		external
	{
		nonfungiblePositionManager.setDefaultProtocolFeeMultiplier(
			_protocolFeeMultiplier
		);
	}

	function setDefaultFeeTo(address _feeTo) external {
		nonfungiblePositionManager.setDefaultFeeTo(_feeTo);
	}

	function setDefaultFeeToSetter(address _feeToSetter) external {
		nonfungiblePositionManager.setDefaultFeeToSetter(_feeToSetter);
	}

	function setDefaultFeeRecipient(address _feeRecipient) external {
		nonfungiblePositionManager.setDefaultFeeRecipient(_feeRecipient);
	}

	function setDefaultTickLower(int24 _tickLower) external {
		nonfungiblePositionManager.setDefaultTickLower(_tickLower);
	}

	function setDefaultTickUpper(int24 _tickUpper) external {
		nonfungiblePositionManager.setDefaultTickUpper(_tickUpper);
	}

	function setDefaultSlippageTolerance(uint24 _slippageTolerance) external {
		nonfungiblePositionManager.setDefaultSlippageTolerance(_slippageTolerance);
	}

	function setDefaultDeadline(uint256 _deadline) external {
		nonfungiblePositionManager.setDefaultDeadline(_deadline);
	}

	function setDefaultToken0(address _token0) external {
		nonfungiblePositionManager.setDefaultToken0(_token0);
	}

	function setDefaultToken1(address _token1) external {
		nonfungiblePositionManager.setDefaultToken1(_token1);
	}

	function setDefaultFee(uint24 _fee) external {
		nonfungiblePositionManager.setDefaultFee(_fee);
	}

	function setDefaultAmount0Desired(uint128 _amount0Desired) external {
		nonfungiblePositionManager.setDefaultAmount0Desired(_amount0Desired);
	}

	function setDefaultAmount1Desired(uint128 _amount1Desired) external {
		nonfungiblePositionManager.setDefaultAmount1Desired(_amount1Desired);
	}

	function setDefaultAmount0Min(uint128 _amount0Min) external {
		nonfungiblePositionManager.setDefaultAmount0Min(_amount0Min);
	}

	function setDefaultAmount1Min(uint128 _amount1Min) external {
		nonfungiblePositionManager.setDefaultAmount1Min(_amount1Min);
	}

	function setDefaultAmount0Min(uint128 _amount0Min, uint256 _deadline)
		external
	{
		nonfungiblePositionManager.setDefaultAmount0Min(_amount0Min, _deadline);
	}

	function setDefaultAmount1Min(uint128 _amount1Min, uint256 _deadline)
		external
	{
		nonfungiblePositionManager.setDefaultAmount1Min(_amount1Min, _deadline);
	}

	function setDefaultAmount0Max(uint128 _amount0Max) external {
		nonfungiblePositionManager.setDefaultAmount0Max(_amount0Max);
	}

	function setDefaultAmount1Max(uint128 _amount1Max) external {
		nonfungiblePositionManager.setDefaultAmount1Max(_amount1Max);
	}

	function setDefaultAmount0Max(uint128 _amount0Max, uint256 _deadline)
		external
	{
		nonfungiblePositionManager.setDefaultAmount0Max(_amount0Max, _deadline);
	}

	function setDefaultAmount1Max(uint128 _amount1Max, uint256 _deadline)
		external
	{
		nonfungiblePositionManager.setDefaultAmount1Max(_amount1Max, _deadline);
	}
	



}







 





