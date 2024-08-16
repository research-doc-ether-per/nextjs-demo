// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommuteManagement is Ownable {
    // 通学予定：ユーザーアドレス -> 通学日時 -> 通学手段（mode）
    mapping(address => mapping(uint256 => uint256)) public commutePlan;
    // 通学実績：ユーザーアドレス -> 通学日時 -> 通学手段（mode）
    mapping(address => mapping(uint256 => uint256)) public commuteActual;
    // チェック済みフラグ：ユーザーアドレス -> 通学日時 -> チェックフラグ
    mapping(address => mapping(uint256 => bool)) public checkFlag;

    // イベントの宣言
    event Registered(address indexed user, uint256 commuteDate, uint256 mode);
    event Cancelled(address indexed user, uint256 commuteDate, uint256 mode);
    event Excluded(address indexed user, uint256 commuteDate, uint256 mode);

    // コンストラクタ：Ownableの初期化
    constructor() Ownable(msg.sender) {}

    /**
     * @dev 通学予定を登録する関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学日時
     * @param mode 通学手段
     */
    function registerCommute(address user, uint256 commuteDate, uint256 mode) public onlyOwner {
        commutePlan[user][commuteDate] = mode;
        emit Registered(user, commuteDate, mode);
    }

    /**
     * @dev 通学予定をキャンセルする関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学日時
     */
    function cancelCommute(address user, uint256 commuteDate) public onlyOwner {
        delete commutePlan[user][commuteDate];
        emit Cancelled(user, commuteDate, commuteActual[user][commuteDate]);
    }

    /**
     * @dev 通学実績をチェック済みにする関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学日時
     */
    function excludeCommute(address user, uint256 commuteDate) public onlyOwner {
        checkFlag[user][commuteDate] = true;
        emit Excluded(user, commuteDate, commuteActual[user][commuteDate]);
    }

    /**
     * @dev 通学手段を取得する関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学日時
     * @return mode 通学手段
     */
    function getCommute(address user, uint256 commuteDate) public view returns (uint256 mode) {
        return commutePlan[user][commuteDate];
    }
}
