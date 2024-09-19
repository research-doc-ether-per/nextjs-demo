// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommuteManagement is Ownable {
    // 付与するポイントタイプ種類
    enum RewardType {
        BOOKING, // 予約
        MATCH, // 予約と実績一致
        SURVEY // アンケート
    }

    // 通学手段種類
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

    // ポイント情報
    struct Reward {
        uint32 date; // 日付
        RewardType rewardType; // 付与するポイントタイプ
        CommuteMode mode; // 通学手段
        uint256 points; // ポイント
    }

    // 通学情報
    struct CommuteInfo {
        address user; // ユーザーアドレス
        CommuteMode mode; // 通学手段
    }

    // マッピング定義：ユーザーアドレス -> ポイント情報リスト
    mapping(address => Reward[]) public userPoints;
    // 通学計画：通学日付 -> ユーザーアドレス -> 通学手段
    mapping(uint32 => mapping(address => CommuteMode)) public commutePlan;
    // 通学実績：通学日付 -> ユーザーアドレス -> 通学手段
    mapping(uint32 => mapping(address => CommuteMode)) public commuteActual;
    // チェック済みフラグ：通学日付 -> ユーザーアドレス -> チェックフラグ
    mapping(uint32 => mapping(address => bool)) public checkFlag;
    // 通学日付 -> 登録されている全ユーザーアドレス
    mapping(uint32 => address[]) public registeredUsers;

    // 付与するポイントを管理するリスト
    Reward[] public rewards;

    // イベントの宣言
    event Registered(
        address indexed user,
        uint32 commuteDate,
        CommuteMode mode
    );
    event Cancelled(address indexed user, uint32 commuteDate, CommuteMode mode);
    event PointsAdded(
        address indexed user,
        uint32 indexed date,
        RewardType rewardType,
        uint256 points,
        CommuteMode mode
    );
    event PointsUpdated(
        address indexed user,
        uint32 indexed date,
        RewardType rewardType,
        uint256 points,
        CommuteMode mode
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
        if (
            _rewardType == RewardType.BOOKING || _rewardType == RewardType.MATCH
        ) {
            _mode = CommuteMode.NONE;
        }

        bool updated = false;
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
     * @dev 指定されたタイプと通学手段に一致する全てのポイント情報を取得する
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
     * @dev ポイントをユーザーに追加する
     * @param _user ユーザーのアドレス
     * @param _date 日付
     * @param _rewardType 付与するポイントタイプ
     * @param _mode 通学手段
     * @param _points 追加するポイント数
     */
    function addPoints(
        address _user,
        uint32 _date,
        RewardType _rewardType,
        CommuteMode _mode,
        uint256 _points
    ) public onlyOwner {
        Reward memory newEntry = Reward({
            date: _date,
            rewardType: _rewardType,
            mode: _mode,
            points: _points
        });
        userPoints[_user].push(newEntry);
        emit PointsAdded(_user, _date, _rewardType, _points, _mode);
    }

    /**
     * @dev ユーザーのポイントを更新する
     * @param _user ユーザーのアドレス
     * @param _date 日付
     * @param _rewardType 付与するポイントタイプ
     * @param _mode 通学手段
     * @param _newPoints 新しいポイント数
     */
    function updatePoints(
        address _user,
        uint32 _date,
        RewardType _rewardType,
        CommuteMode _mode,
        uint256 _newPoints
    ) public onlyOwner {
        Reward[] storage entries = userPoints[_user];
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                entries[i].date == _date &&
                entries[i].rewardType == _rewardType &&
                entries[i].mode == _mode
            ) {
                entries[i].points = _newPoints;
                emit PointsUpdated(
                    _user,
                    _date,
                    _rewardType,
                    _newPoints,
                    _mode
                );
                return;
            }
        }
        revert("Point entry not found");
    }

    /**
     * @dev 通学計画を登録する
     * @param _commuteDate 通学日付
     * @param _user ユーザーのアドレス
     * @param _mode 通学手段
     */
    function registerCommute(
        uint32 _commuteDate,
        address _user,
        CommuteMode _mode
    ) public onlyOwner {
        require(
            commutePlan[_commuteDate][_user] == CommuteMode.NONE,
            "Commute already registered"
        );

        commutePlan[_commuteDate][_user] = _mode;
        registeredUsers[_commuteDate].push(_user);
        emit Registered(_user, _commuteDate, _mode);
    }

    /**
     * @dev 通学計画をキャンセルする
     * @param _commuteDate 通学日付
     * @param _user ユーザーのアドレス
     */
    function cancelCommute(uint32 _commuteDate, address _user)
        public
        onlyOwner
    {
        require(
            commutePlan[_commuteDate][_user] != CommuteMode.NONE,
            "No commute registered"
        );

        CommuteMode _mode = commutePlan[_commuteDate][_user];
        delete commutePlan[_commuteDate][_user];

        address[] storage users = registeredUsers[_commuteDate];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                users[i] = users[users.length - 1];
                users.pop();
                break;
            }
        }

        emit Cancelled(_user, _commuteDate, _mode);
    }

    /**
     * @dev 通学実績を更新する
     * @param _commuteDate 通学日付
     * @param _user ユーザーのアドレス
     * @param _mode 通学手段
     * @param _updateFlag 更新フラグ
     */
    function updateCommuteActual(
        uint32 _commuteDate,
        address _user,
        CommuteMode _mode,
        bool _updateFlag
    ) public onlyOwner {
        commuteActual[_commuteDate][_user] = _mode;
        checkFlag[_commuteDate][_user] = _updateFlag;
    }

    /**
     * @dev 特定の通学日付に予約している全てのユーザーとその通学手段を取得する
     * @param _commuteDate 通学日付
     * @return _commuteInfos 通学情報のリスト
     */
    function getCommuteInfosByTime(uint32 _commuteDate)
        public
        view
        returns (CommuteInfo[] memory _commuteInfos)
    {
        address[] memory users = registeredUsers[_commuteDate];
        _commuteInfos = new CommuteInfo[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            CommuteMode mode = commutePlan[_commuteDate][user];
            _commuteInfos[i] = CommuteInfo(user, mode);
        }

        return _commuteInfos;
    }
}
