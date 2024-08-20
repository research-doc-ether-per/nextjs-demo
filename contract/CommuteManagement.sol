// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommuteManagement is Ownable {
    // 通学手段の定義
    enum CommuteMode {
        NONE,              // 未設定
        BUS,               // バス
        BUS_TRANSFER,      // バス＋バス（乗り継ぎ）
        BUS_MONORAIL_TRANSFER, // バス+モノレール（乗り継ぎ）
        BUS_WALK,          // バス+徒歩
        PRIVATE_CAR,       // 自家用車
        OTHER,             // その他
        DAY_OFF            // 休み
    }

    struct CommuteInfo {
        address user;
        CommuteMode mode;
    }
    
    // 通学計画：通学時間 -> ユーザーアドレス -> 通学手段（mode）
    mapping(uint32 => mapping(address => CommuteMode)) public commutePlan;
    // 通学実績：通学時間 -> ユーザーアドレス -> 通学手段（mode）
    mapping(uint32 => mapping(address => CommuteMode)) public commuteActual;
    // チェック済みフラグ：通学時間 -> ユーザーアドレス -> チェックフラグ
    mapping(uint32 => mapping(address => bool)) public checkFlag;
    // 通学時間 -> 登録されている全ユーザーアドレス
    mapping(uint32 => address[]) public registeredUsers;

    // イベントの宣言
    event Registered(address indexed user, uint32 commuteDate, CommuteMode mode);
    event Cancelled(address indexed user, uint32 commuteDate, CommuteMode mode);

    // コンストラクタ：Ownableの初期化
    constructor() Ownable(msg.sender) {}

    /**
     * @dev 通学計画を登録する関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学時間
     * @param mode 通学手段
     */
    function registerCommute(uint32 commuteDate, address user, CommuteMode mode) public onlyOwner {
        require(commutePlan[commuteDate][user] == CommuteMode.NONE, "Commute already registered");

        commutePlan[commuteDate][user] = mode;
        registeredUsers[commuteDate].push(user); 
        emit Registered(user, commuteDate, mode);
    }

    /**
     * @dev 通学計画をキャンセルする関数
     * @param user ユーザーのアドレス
     * @param commuteDate 通学時間
     */
    function cancelCommute(uint32 commuteDate, address user) public onlyOwner {
        require(commutePlan[commuteDate][user] != CommuteMode.NONE, "No commute registered");

        // 通学計画からユーザーを削除
        CommuteMode mode = commutePlan[commuteDate][user];
        delete commutePlan[commuteDate][user];

        // registeredUsersからユーザーを削除
        address[] storage users = registeredUsers[commuteDate];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) {
                users[i] = users[users.length - 1]; // 最後の要素で置き換える
                users.pop(); // 最後の要素を削除
                break;
            }
        }

        emit Cancelled(user, commuteDate, mode);
    }

    /**
     * @dev 通学実績を更新する関数
     * @param commuteDate 通学時間
     * @param user ユーザーのアドレス
     * @param mode 実際の通学手段
     * @param updateFlag ポイント付与済みフラグ
     */
    function updateCommuteActual(uint32 commuteDate, address user, CommuteMode mode, bool updateFlag) public onlyOwner {
        commuteActual[commuteDate][user] = mode;
        checkFlag[commuteDate][user] = updateFlag;
    }


    /**
     * @dev 特定の通学時間に予約している全てのユーザーとその通学手段を取得する関数
     * @param commuteDate 通学時間
     * @return commuteInfos 予約している全ユーザーとその通学手段のリスト
     */
    function getCommuteInfosByTime(uint32 commuteDate) public view returns (CommuteInfo[] memory commuteInfos) {
        address[] memory users = registeredUsers[commuteDate];
        commuteInfos = new CommuteInfo[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            CommuteMode mode = commutePlan[commuteDate][user];
            commuteInfos[i] = CommuteInfo(user, mode);
        }

        return commuteInfos;
    }
}
