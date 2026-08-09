import 'package:flutter/material.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/profile_result_page.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({required this.apiClient, super.key});

  final ProfileApiClient apiClient;

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController(
    text: 'Asia/Shanghai',
  );
  DateTime? _birthDateTime;
  bool _submitting = false;

  @override
  void dispose() {
    _placeController.dispose();
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
      final LifeProfile profile =
          await widget.apiClient.generateProfile(birthInput);
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
    return Scaffold(
      appBar: AppBar(title: const Text('天人律')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                '建立你的生命档案',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('请提供准确的出生时间与地点。所有结果仅作个人节律观察参考。'),
              const SizedBox(height: 24),
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
                      validator: (String? value) => _coordinate(value, -90, 90),
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
                    : const Text('生成生命档案'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
