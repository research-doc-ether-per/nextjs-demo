// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PointManager is ERC20, Ownable {
    // ユーザーごとの累積ポイント
    mapping(address => uint256) public accumulatedPoints;

    // コンストラクタ：ERC20トークンの名前とシンボルを設定
    constructor() ERC20("PointToken", "PT") Ownable(msg.sender) {}

    /**
     * @dev ポイントを追加する関数
     * @param user ユーザーのアドレス
     * @param amount 追加するポイント数
     */
    function addPoint(address user, uint256 amount) public onlyOwner {
        _mint(user, amount);
        accumulatedPoints[user] += amount;
    }

    /**
     * @dev ポイントを減少させる関数
     * @param user ユーザーのアドレス
     * @param amount 減少させるポイント数
     */
    function subPoint(address user, uint256 amount) public onlyOwner {
        require(balanceOf(user) >= amount, "Insufficient points");
        _burn(user, amount);
        accumulatedPoints[user] -= amount;
    }

    /**
     * @dev ポイントを転送する関数
     * @param from ポイントを送るユーザーのアドレス
     * @param to ポイントを受け取るユーザーのアドレス
     * @param amount 転送するポイント数
     */
    function transferPoint(address from, address to, uint256 amount) public onlyOwner {
        require(balanceOf(from) >= amount, "Insufficient points");
        _transfer(from, to, amount);
    }

    /**
     * @dev ユーザーのポイント残高を確認する関数
     * @param user ユーザーのアドレス
     * @return 残高ポイント数
     */
    function balanceOfPoint(address user) public view returns (uint256) {
        return balanceOf(user);
    }
}
