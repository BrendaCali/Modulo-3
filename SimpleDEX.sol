// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    address public owner;
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event SwapAforB(address indexed trader, uint256 amountAIn, uint256 amountBOut);
    event SwapBforA(address indexed trader, uint256 amountBIn, uint256 amountAOut);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }
    
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        // Transfer tokens from owner to DEX
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of TokenA failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of TokenB failed");
        
        // Update reserves
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calculate amount of TokenB to send (with 0.3% fee)
        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        uint256 amountBOutWithFee = (amountBOut * 997) / 1000; // 0.3% fee
        
        require(amountBOutWithFee > 0, "Insufficient output amount");
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "Transfer of TokenA failed");
        
        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOutWithFee;
        
        require(tokenB.transfer(msg.sender, amountBOutWithFee), "Transfer of TokenB failed");
        
        emit SwapAforB(msg.sender, amountAIn, amountBOutWithFee);
    }
    
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calculate amount of TokenA to send (with 0.3% fee)
        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        uint256 amountAOutWithFee = (amountAOut * 997) / 1000; // 0.3% fee
        
        require(amountAOutWithFee > 0, "Insufficient output amount");
        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "Transfer of TokenB failed");
        
        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOutWithFee;
        
        require(tokenA.transfer(msg.sender, amountAOutWithFee), "Transfer of TokenA failed");
        
        emit SwapBforA(msg.sender, amountBIn, amountAOutWithFee);
    }
    
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");
        
        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens back to owner
        require(tokenA.transfer(msg.sender, amountA), "Transfer of TokenA failed");
        require(tokenB.transfer(msg.sender, amountB), "Transfer of TokenB failed");
        
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }
    
    function getPrice(address _token) external view returns (uint256) {
        if (_token == address(tokenA)) {
            require(reserveA > 0, "No liquidity for TokenA");
            return (reserveB * 1e18) / reserveA; // Price of A in terms of B
        } else if (_token == address(tokenB)) {
            require(reserveB > 0, "No liquidity for TokenB");
            return (reserveA * 1e18) / reserveB; // Price of B in terms of A
        } else {
            revert("Invalid token address");
        }
    }
}