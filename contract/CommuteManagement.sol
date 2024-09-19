// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommuteManagement is Ownable {
    // 付与するポイントタイプの定義
    enum RewardType {
        BOOKING, // 予約
        MATCH, // 予約と実績一致
        SURVEY // アンケート
    }

    // 通学手段の定義
    enum CommuteMode {
        NONE, // 未設定
        BUS, // バス
        BUS_TRANSFER, // バス＋バス（乗り継ぎ）
        BUS_MONORAIL_TRANSFER, // バス+モノレール（乗り継ぎ）
        BUS_WALK, // バス+徒歩
        PRIVATE_CAR, // 自家用車
        OTHER, // その他
        DAY_OFF // 休み
    }

    struct CommuteInfo {
        address user; // 利用者アドレス
        CommuteMode mode; // 通学手段
        uint256 points; // 累計実験ポイント
    }

    struct Reward {
        uint32 date; // 日付
        RewardType rewardType; // 付与するポイントタイプ
        CommuteMode mode; // 通学手段
        uint256 points; // ポイント
    }

    Reward[] public rewards;

    // 通学計画：通学日時 -> ユーザーアドレス -> 通学手段
    mapping(uint32 => mapping(address => CommuteInfo)) public commutePlan;
    // 通学実績：通学日時 -> ユーザーアドレス -> 通学手段
    mapping(uint32 => mapping(address => CommuteInfo)) public commuteActual;
    // チェック済みフラグ：通学日時 -> ユーザーアドレス -> チェックフラグ
    mapping(uint32 => mapping(address => bool)) public checkFlag;
    // 通学日時 -> 登録されている全ユーザーアドレス
    mapping(uint32 => address[]) public registeredUsers;

    // イベントの宣言
    event Registered(
        address indexed user,
        uint32 commuteDate,
        CommuteMode mode,
        uint256 points
    );
    event Cancelled(
        address indexed user,
        uint32 commuteDate,
        CommuteMode mode,
        uint256 points
    );

    // コンストラクタ：Ownableの初期化
    constructor() Ownable(msg.sender) {}

    /**
     * @dev 付与するポイントを登録・更新する
     * @param _date 日付
     * @param _rewardType 付与するポイントタイプ
     * @param _mode 通学手段
     * @param _points ポイント
     */
    function addReward(
        uint32 _date,
        RewardType _rewardType,
        CommuteMode _mode,
        uint256 _points
    ) public onlyOwner {
        // 付与するポイントタイプは予約、または、アンケートの場合、通学手段を未設定にする
        if (
            _rewardType == RewardType.BOOKING || _rewardType == RewardType.MATCH
        ) {
            _mode = CommuteMode.NONE;
        }

        bool updated = false;

        // 既存のデータをチェックして、存在の場合更新
        for (uint256 i = 0; i < rewards.length; i++) {
            if (
                rewards[i].date == _date &&
                rewards[i].rewardType == _rewardType &&
                rewards[i].mode == _mode
            ) {
                rewards[i].points = _points;
                updated = true;
                break;
            }
        }

        // 更新されなかった場合、追加
        if (!updated) {
            Reward memory newReward = Reward({
                date: _date,
                rewardType: _rewardType,
                mode: _mode,
                points: _points
            });

            rewards.push(newReward);
        }
    }

    /**
     * @dev 指定されたタイプと通学手段に一致する全ての報酬を取得する
     * @param _rewardType 付与するポイントタイプ
     * @param _mode 通学手段
     * @return matchedRewards 付与するポイントのリスト
     */
    function getRewardsByTypeAndMode(RewardType _rewardType, CommuteMode _mode)
        public
        view
        returns (Reward[] memory)
    {
        uint256 matchCount = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            if (
                rewards[i].rewardType == _rewardType && rewards[i].mode == _mode
            ) {
                matchCount++;
            }
        }

        Reward[] memory matchedRewards = new Reward[](matchCount);
        uint256 index = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            if (
                rewards[i].rewardType == _rewardType && rewards[i].mode == _mode
            ) {
                matchedRewards[index] = rewards[i];
                index++;
            }
        }

        return matchedRewards;
    }

    /**
     * @dev 通学計画を登録する
     * @param _user ユーザーのアドレス
     * @param _commuteDate 通学日時
     * @param _mode 通学手段
     * @param _points 付与するポイント
     */
    function registerCommute(
        uint32 _commuteDate,
        address _user,
        CommuteMode _mode,
        uint256 _points
    ) public onlyOwner {
        require(
            commutePlan[_commuteDate][_user].mode == CommuteMode.NONE,
            "Commute already registered."
        );

        commutePlan[_commuteDate][_user].user = _user;
        commutePlan[_commuteDate][_user].mode = _mode;
        commutePlan[_commuteDate][_user].points += _points;

        registeredUsers[_commuteDate].push(_user);

        emit Registered(_user, _commuteDate, _mode, _points);
    }

    /**
     * @dev 通学計画をキャンセルする
     * @param _user ユーザーのアドレス
     * @param _commuteDate 通学日時
     * @param _points 付与するポイント
     */
    function cancelCommute(
        uint32 _commuteDate,
        address _user,
        uint256 _points
    ) public onlyOwner {
        require(
            commutePlan[_commuteDate][_user].mode != CommuteMode.NONE,
            "No commute registered."
        );

        // 通学計画からユーザーを削除
        CommuteMode mode = commutePlan[_commuteDate][_user].mode;

        commutePlan[_commuteDate][_user].mode = CommuteMode.NONE;
        commutePlan[_commuteDate][_user].points -= _points;

        // registeredUsersからユーザーを削除
        address[] storage users = registeredUsers[_commuteDate];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                users[i] = users[users.length - 1]; // 最後の要素で置き換える
                users.pop(); // 最後の要素を削除
                break;
            }
        }

        emit Cancelled(_user, _commuteDate, mode, _points);
    }

    /**
     * @dev 通学実績を更新する
     * @param _commuteDate 通学日時
     * @param _user ユーザーのアドレス
     * @param _mode 実際の通学手段
     * @param _points 付与するポイント
     * @param _updateFlag ポイント付与済みフラグ
     */
    function updateCommuteActual(
        uint32 _commuteDate,
        address _user,
        CommuteMode _mode,
        uint256 _points,
        bool _updateFlag
    ) public onlyOwner {
        commuteActual[_commuteDate][_user].user = _user;
        commuteActual[_commuteDate][_user].mode = _mode;
        commuteActual[_commuteDate][_user].points += _points;

        checkFlag[_commuteDate][_user] = _updateFlag;
    }

    /**
     * @dev 特定の通学日時に予約している全てのユーザーとその通学手段を取得する
     * @param _commuteDate 通学日時
     * @return commuteInfos 予約している全ユーザーとその通学手段のリスト
     */
    function getCommuteInfosByTime(uint32 _commuteDate)
        public
        view
        returns (CommuteInfo[] memory commuteInfos)
    {
        address[] memory users = registeredUsers[_commuteDate];
        commuteInfos = new CommuteInfo[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            CommuteMode mode = commutePlan[_commuteDate][user].mode;
            uint256 points = commutePlan[_commuteDate][user].points;
            commuteInfos[i] = CommuteInfo(user, mode, points);
        }

        return commuteInfos;
    }
}
