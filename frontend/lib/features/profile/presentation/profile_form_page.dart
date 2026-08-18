import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/profile_result_page.dart';
import 'package:tianrenlu/features/profile/presentation/saved_profiles_page.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({
    required this.apiClient,
    this.accountPageBuilder,
    this.initialProfile,
    super.key,
  });

  final ProfileApiClient apiClient;
  final Widget Function()? accountPageBuilder;
  final LifeProfile? initialProfile;

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(
    text: '我的生命档案',
  );
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController(
    text: 'Asia/Shanghai',
  );
  DateTime? _birthDateTime;
  bool _submitting = false;
  bool _searchingPlace = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final LifeProfile? profile = widget.initialProfile;
    final BirthInput? birth = profile?.birthInput;
    if (profile != null) {
      _nameController.text = profile.name;
      _isDefault = profile.isDefault;
    }
    if (birth != null) {
      _birthDateTime = birth.occurredAt;
      _placeController.text = birth.placeName;
      _latitudeController.text = birth.latitude.toString();
      _longitudeController.text = birth.longitude.toString();
      _timezoneController.text = birth.timezone;
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthTime() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _birthDateTime ?? DateTime(now.year - 25),
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _birthDateTime ?? DateTime(now.year - 25),
      ),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _birthDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDateTime == null) {
      if (_birthDateTime == null) {
        _showMessage('请选择出生日期和时间。');
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final BirthInput birthInput = BirthInput(
        occurredAt: _birthDateTime!,
        placeName: _placeController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        timezone: _timezoneController.text.trim(),
      );
      final LifeProfile profile;
      if (widget.initialProfile?.id == null) {
        profile = await widget.apiClient.saveProfile(
          birthInput,
          name: _nameController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        profile = await widget.apiClient.updateProfile(
          widget.initialProfile!.id!,
          birthInput,
          name: _nameController.text.trim(),
          isDefault: _isDefault,
        );
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProfileResultPage(
            profile: profile,
            birthInput: birthInput,
            apiClient: widget.apiClient,
          ),
        ),
      );
    } on ProfileApiException catch (error) {
      _showMessage(error.message);
    } on FormatException {
      _showMessage('经纬度格式不正确。');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _searchPlace() async {
    final String query = _placeController.text.trim();
    if (query.length < 2) {
      _showMessage('请输入至少两个字符后再搜索地点。');
      return;
    }
    setState(() => _searchingPlace = true);
    try {
      final List<LocationCandidate> results =
          await widget.apiClient.searchLocations(query);
      if (!mounted) {
        return;
      }
      if (results.isEmpty) {
        _showMessage('未找到匹配地点，请尝试更完整的城市或地区名称。');
        return;
      }
      final LocationCandidate? selected =
          await showModalBottomSheet<LocationCandidate>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext context) => SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final LocationCandidate candidate = results[index];
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(candidate.displayName),
                subtitle: Text(candidate.timezone),
                onTap: () => Navigator.of(context).pop(candidate),
              );
            },
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          _placeController.text = selected.displayName;
          _latitudeController.text = selected.latitude.toStringAsFixed(6);
          _longitudeController.text = selected.longitude.toStringAsFixed(6);
          _timezoneController.text = selected.timezone;
        });
      }
    } on ProfileApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _searchingPlace = false);
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? '此项必填' : null;

  String? _coordinate(String? value, double min, double max) {
    final double? number = double.tryParse(value ?? '');
    if (number == null || number < min || number > max) {
      return '请输入 $min 至 $max 之间的数值';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.initialProfile == null ? '天人律' : '编辑生命档案'),
        actions: <Widget>[
          IconButton(
            tooltip: '我的档案',
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SavedProfilesPage(apiClient: widget.apiClient),
              ),
            ),
          ),
          if (widget.accountPageBuilder != null)
            IconButton(
              tooltip: '账户与隐私',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => widget.accountPageBuilder!(),
                ),
              ),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[t.backgroundTop, t.backgroundBottom])),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: t.outline)),
                  child: Row(children: <Widget>[
                    Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: <Color>[
                              t.glow.withValues(alpha: .86),
                              t.accentSoft,
                              t.surfaceStrong
                            ]),
                            border: Border.all(color: t.outline)),
                        child: Icon(Icons.spa_outlined,
                            color: t.accent, size: 30)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                          Text('建立你的生命档案',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('准确记录时间与地点，结果仅作个人节律观察参考。',
                              style: TextStyle(
                                  color: t.textSecondary, height: 1.4)),
                        ]))
                  ]),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '档案名称',
                    hintText: '例如：我的档案',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 80,
                  validator: _required,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('设为默认档案'),
                  subtitle: const Text('登录后首页优先展示此档案'),
                  value: _isDefault,
                  onChanged: (bool value) => setState(() => _isDefault = value),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _selectBirthTime,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_birthDateTime?.toString() ?? '选择出生日期和时间'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _placeController,
                  decoration: const InputDecoration(
                    labelText: '出生地点',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _searchingPlace ? null : _searchPlace,
                    icon: _searchingPlace
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('搜索并自动填写'),
                  ),
                ),
                const Text(
                  '地点数据 © OpenStreetMap contributors',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: '纬度',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (String? value) =>
                            _coordinate(value, -90, 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: '经度',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (String? value) =>
                            _coordinate(value, -180, 180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timezoneController,
                  decoration: const InputDecoration(
                    labelText: 'IANA 时区',
                    helperText: '例如 Asia/Shanghai',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.initialProfile == null ? '生成并保存档案' : '保存修改'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
