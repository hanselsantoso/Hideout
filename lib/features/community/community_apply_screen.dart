import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';

const _regions = [
  'Jakarta',
  'Surabaya',
  'Bandung',
  'Yogyakarta',
  'Medan',
  'Bali',
  'Makassar',
  'Semarang',
  'Palembang',
  'Lainnya',
];

const _communityTypes = [
  'Kompetitif',
  'Kasual & Komunitas',
  'Campuran',
  'Regional Club',
  'Sekolah / Kampus',
];

const _banks = [
  'BCA',
  'Bank Mandiri',
  'BNI',
  'BRI',
  'CIMB Niaga',
  'BSI',
  'Bank Permata',
  'Danamon',
];

class CommunityApplyScreen extends ConsumerStatefulWidget {
  const CommunityApplyScreen({super.key});

  @override
  ConsumerState<CommunityApplyScreen> createState() =>
      _CommunityApplyScreenState();
}

class _CommunityApplyScreenState extends ConsumerState<CommunityApplyScreen> {
  int _step = 0;
  bool _submitted = false;
  bool _busy = false;
  bool _logoUploaded = false;
  bool _idUploaded = false;
  bool _letterUploaded = false;
  bool _agreeBank = false;
  bool _agreeFinal = false;
  String? _error;

  final _communityName = TextEditingController();
  final _tag = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _leaderName = TextEditingController();
  final _leaderEmail = TextEditingController();
  final _leaderPhone = TextEditingController();
  final _leaderInstagram = TextEditingController();
  final _leaderUserId = TextEditingController();
  final _bankNumber = TextEditingController();
  final _bankHolder = TextEditingController();
  final _bankBranch = TextEditingController();

  String _type = '';
  String _region = '';
  String _bank = '';

  @override
  void dispose() {
    _communityName.dispose();
    _tag.dispose();
    _city.dispose();
    _description.dispose();
    _website.dispose();
    _leaderName.dispose();
    _leaderEmail.dispose();
    _leaderPhone.dispose();
    _leaderInstagram.dispose();
    _leaderUserId.dispose();
    _bankNumber.dispose();
    _bankHolder.dispose();
    _bankBranch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _successView();

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HIDEOUT - PENDAFTARAN KOMUNITAS',
                style: HDTText.overline(size: 9)),
            Text('BUKA KOMUNITAS BARU', style: HDTText.display(size: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: HDTSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: HDTColors.accent,
                    borderRadius: HDTR.sm,
                  ),
                  child: const Icon(Icons.sports_martial_arts,
                      size: 15, color: Colors.white),
                ),
                const SizedBox(width: HDTSpace.sm),
                Text('HIDEOUT', style: HDTText.display(size: 16)),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth > 920 ? 920 : constraints.maxWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    HDTSpace.lg, HDTSpace.xl, HDTSpace.lg, 120),
                children: [
                  _StepBar(step: _step),
                  const SizedBox(height: HDTSpace.xxl),
                  _currentStep(),
                  if (_error != null) ...[
                    const SizedBox(height: HDTSpace.lg),
                    _Notice(
                      icon: Icons.error_outline,
                      color: HDTColors.danger,
                      text: _error!,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomActions(
        canBack: _step > 0,
        busy: _busy,
        nextLabel: _step == 3 ? 'KIRIM PENGAJUAN' : 'CONTINUE',
        onBack: _step > 0 ? _back : null,
        onNext: _busy ? null : _next,
      ),
    );
  }

  Widget _currentStep() {
    return switch (_step) {
      0 => _identityStep(),
      1 => _leaderStep(),
      2 => _bankStep(),
      _ => _reviewStep(),
    };
  }

  Widget _identityStep() {
    return _StepSection(
      step: 'LANGKAH 1',
      title: 'IDENTITAS KOMUNITAS',
      subtitle:
          'Isi informasi dasar komunitas. Nama dan tag akan tampil di bracket, leaderboard, dan halaman publik.',
      children: [
        _Field(
          label: 'NAMA KOMUNITAS',
          controller: _communityName,
          hint: 'contoh: JKT WOLVES',
          maxLength: 40,
          textCapitalization: TextCapitalization.characters,
        ),
        _Field(
          label: 'TAG / KODE SINGKAT',
          controller: _tag,
          hint: 'JKTWLV',
          maxLength: 8,
          onChanged: (value) {
            final clean =
                value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
            if (clean != value) {
              _tag.value = TextEditingValue(
                text: clean,
                selection: TextSelection.collapsed(offset: clean.length),
              );
            }
          },
        ),
        _SelectField(
          label: 'TIPE KOMUNITAS',
          value: _type,
          options: _communityTypes,
          onChanged: (value) => setState(() => _type = value),
        ),
        _SelectField(
          label: 'REGION KOMUNITAS',
          value: _region,
          options: _regions,
          onChanged: (value) => setState(() => _region = value),
        ),
        _Field(label: 'KOTA / KABUPATEN', controller: _city),
        _Field(
          label: 'WEBSITE / SOSMED',
          controller: _website,
          hint: 'instagram.com/komunitas',
          icon: Icons.language,
        ),
        _Wide(
          child: _Field(
            label: 'DESKRIPSI KOMUNITAS',
            controller: _description,
            hint: 'Ceritakan visi, kegiatan rutin, target anggota, dan arena.',
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
          ),
        ),
        _Wide(
          child: _UploadMock(
            label: 'LOGO KOMUNITAS',
            hint: 'PNG / JPG, maks 2MB, min 200x200px',
            uploaded: _logoUploaded,
            optional: true,
            onTap: () => setState(() => _logoUploaded = true),
          ),
        ),
        const _Wide(
          child: _Notice(
            icon: Icons.info_outline,
            color: HDTColors.accentHover,
            text:
                'Data komunitas dapat diubah setelah disetujui melalui Community Settings. Nama dan tag sebaiknya dianggap permanen.',
          ),
        ),
      ],
    );
  }

  Widget _leaderStep() {
    return _StepSection(
      step: 'LANGKAH 2',
      title: 'PROFIL KETUA',
      subtitle:
          'Ketua akan menjadi Admin Komunitas pertama dan bertanggung jawab atas aktivitas komunitas di platform.',
      children: [
        _Field(label: 'NAMA LENGKAP', controller: _leaderName),
        _Field(
          label: 'EMAIL',
          controller: _leaderEmail,
          keyboardType: TextInputType.emailAddress,
          hint: 'ketua@email.com',
        ),
        _Field(
          label: 'NOMOR HP / WHATSAPP',
          controller: _leaderPhone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _Field(
          label: 'INSTAGRAM / SOSMED',
          controller: _leaderInstagram,
          icon: Icons.alternate_email,
          hint: 'tanpa @',
        ),
        _Wide(
          child: _Field(
            label: 'USER KETUA / HIDEOUT ID',
            controller: _leaderUserId,
            hint: 'Kosongkan jika ketua adalah akun yang sedang login',
            icon: Icons.badge_outlined,
          ),
        ),
        _UploadMock(
          label: 'KTP / KARTU IDENTITAS',
          hint: 'JPG / PNG, maks 5MB',
          uploaded: _idUploaded,
          onTap: () => setState(() => _idUploaded = true),
        ),
        _UploadMock(
          label: 'SURAT KETERANGAN KOMUNITAS',
          hint: 'Opsional, PDF / JPG',
          uploaded: _letterUploaded,
          optional: true,
          onTap: () => setState(() => _letterUploaded = true),
        ),
        const _Wide(
          child: _Notice(
            icon: Icons.shield_outlined,
            color: HDTColors.warning,
            text:
                'KTP digunakan hanya untuk verifikasi internal HIDEOUT dan tidak ditampilkan ke publik.',
          ),
        ),
      ],
    );
  }

  Widget _bankStep() {
    return _StepSection(
      step: 'LANGKAH 3',
      title: 'INFORMASI REKENING',
      subtitle:
          'Rekening komunitas untuk menerima dana pendaftaran setelah turnamen selesai.',
      children: [
        const _Wide(
          child: _Notice(
            icon: Icons.credit_card,
            color: HDTColors.info,
            text:
                'Pembayaran peserta nanti diproses via Midtrans. Untuk MVP web ini payment masih dianggap lunas otomatis.',
          ),
        ),
        _SelectField(
          label: 'NAMA BANK',
          value: _bank,
          options: _banks,
          onChanged: (value) => setState(() => _bank = value),
        ),
        _Field(
          label: 'NOMOR REKENING',
          controller: _bankNumber,
          icon: Icons.tag,
          keyboardType: TextInputType.number,
        ),
        _Wide(
          child: _Field(
            label: 'NAMA PEMEGANG REKENING',
            controller: _bankHolder,
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        _Wide(
          child: _Field(
            label: 'CABANG BANK',
            controller: _bankBranch,
            icon: Icons.account_balance_outlined,
            hint: 'Opsional',
          ),
        ),
        _Wide(
          child: _CheckRow(
            value: _agreeBank,
            onChanged: (value) => setState(() => _agreeBank = value),
            text:
                'Saya menyatakan rekening ini benar dan dapat digunakan untuk withdraw dana komunitas.',
          ),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return _StepSection(
      step: 'LANGKAH 4',
      title: 'REVIEW PENGAJUAN',
      subtitle:
          'Periksa kembali data sebelum dikirim ke super admin. Proses review biasanya 3-5 hari kerja.',
      children: [
        _Wide(
          child: Container(
            padding: const EdgeInsets.all(HDTSpace.lg),
            decoration: hdtCard(),
            child: Column(
              children: [
                _ReviewRow('Komunitas', _communityName.text),
                _ReviewRow('Tag', _tag.text),
                _ReviewRow('Tipe', _type),
                _ReviewRow('Region', _region),
                _ReviewRow('Kota', _city.text),
                _ReviewRow('Ketua', _leaderName.text),
                _ReviewRow('Email', _leaderEmail.text),
                _ReviewRow('Rekening', '${_bankHolder.text} - $_bank'),
                _ReviewRow(
                    'Dokumen', _idUploaded ? 'KTP uploaded' : 'Belum lengkap'),
              ],
            ),
          ),
        ),
        _Wide(
          child: _CheckRow(
            value: _agreeFinal,
            onChanged: (value) => setState(() => _agreeFinal = value),
            text:
                'Saya menyatakan seluruh informasi benar dan bersedia mengikuti aturan komunitas HIDEOUT.',
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(HDTSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: HDTColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: HDTColors.success, width: 2),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: HDTColors.success, size: 44),
                ),
                const SizedBox(height: HDTSpace.xl),
                Text('PENGAJUAN\nTERKIRIM.',
                    textAlign: TextAlign.center,
                    style: HDTText.display(size: 40).copyWith(height: 1)),
                const SizedBox(height: HDTSpace.md),
                Text(
                  'Pengajuan ${_communityName.text.isEmpty ? 'komunitas baru' : _communityName.text} sedang dalam review super admin. Hasil review akan dikirim setelah verifikasi data.',
                  textAlign: TextAlign.center,
                  style: HDTText.body(color: HDTColors.text2, height: 1.6),
                ),
                const SizedBox(height: HDTSpace.xl),
                Container(
                  padding: const EdgeInsets.all(HDTSpace.lg),
                  decoration: hdtCard(),
                  child: const Column(
                    children: [
                      _NextStep('01', 'Konfirmasi pengajuan tersimpan'),
                      _NextStep('02', 'Super admin meninjau komunitas'),
                      _NextStep('03', 'Ketua mendapat role admin komunitas'),
                      _NextStep('04', 'Komunitas bisa membuat tournament'),
                    ],
                  ),
                ),
                const SizedBox(height: HDTSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                        child: const Text('HOME'),
                      ),
                    ),
                    const SizedBox(width: HDTSpace.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/dashboard'),
                        child: const Text('DASHBOARD'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _back() {
    setState(() {
      _error = null;
      _step = (_step - 1).clamp(0, 3);
    });
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() {
        _error = null;
        _step++;
      });
      return;
    }
    await _submit();
  }

  bool _validateStep() {
    String? message;
    if (_step == 0) {
      if (_communityName.text.trim().length < 3) {
        message = 'Nama komunitas minimal 3 karakter.';
      } else if (_tag.text.trim().length < 2) {
        message = 'Tag komunitas minimal 2 karakter.';
      } else if (_type.isEmpty ||
          _region.isEmpty ||
          _city.text.trim().isEmpty) {
        message = 'Lengkapi tipe, region, dan kota komunitas.';
      } else if (_description.text.trim().length < 30) {
        message = 'Deskripsi komunitas minimal 30 karakter.';
      }
    }
    if (_step == 1) {
      if (_leaderName.text.trim().isEmpty ||
          _leaderEmail.text.trim().isEmpty ||
          _leaderPhone.text.trim().length < 10 ||
          _leaderInstagram.text.trim().isEmpty) {
        message = 'Lengkapi data ketua komunitas.';
      } else if (!_idUploaded) {
        message = 'Upload KTP / kartu identitas ketua terlebih dahulu.';
      }
    }
    if (_step == 2) {
      if (_bank.isEmpty ||
          _bankNumber.text.trim().length < 8 ||
          _bankHolder.text.trim().isEmpty) {
        message = 'Lengkapi data rekening komunitas.';
      } else if (!_agreeBank) {
        message = 'Setujui pernyataan rekening terlebih dahulu.';
      }
    }
    if (_step == 3 && !_agreeFinal) {
      message = 'Setujui pernyataan final sebelum mengirim pengajuan.';
    }

    setState(() => _error = message);
    return message == null;
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      Navigator.pushNamed(context, '/signup');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final details = [
        _description.text.trim(),
        '',
        'Tag: ${_tag.text.trim()}',
        'Type: $_type',
        'Region: $_region',
        'Website: ${_website.text.trim().isEmpty ? '-' : _website.text.trim()}',
        'Leader: ${_leaderName.text.trim()} / ${_leaderEmail.text.trim()} / ${_leaderPhone.text.trim()}',
        'Instagram: ${_leaderInstagram.text.trim()}',
        'Bank: $_bank - ${_bankHolder.text.trim()} (${_bankNumber.text.trim()})',
        'Documents: KTP ${_idUploaded ? 'OK' : 'missing'}, Letter ${_letterUploaded ? 'OK' : 'none'}, Logo ${_logoUploaded ? 'OK' : 'none'}',
      ].join('\n');

      await ref.read(communityRepositoryProvider).submitApplication(
            requesterId: user.uid,
            communityName: _communityName.text,
            city: _city.text,
            leaderUserId: _leaderUserId.text.trim().isEmpty
                ? user.uid
                : _leaderUserId.text,
            description: details,
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Pengajuan belum bisa dikirim. Coba ulangi beberapa saat lagi.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});
  final int step;
  static const labels = ['IDENTITAS', 'KETUA', 'REKENING', 'REVIEW'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == step
                      ? HDTColors.accent
                      : i < step
                          ? HDTColors.success.withValues(alpha: 0.16)
                          : HDTColors.bg,
                  border: Border.all(
                    color: i == step
                        ? HDTColors.accent
                        : i < step
                            ? HDTColors.success
                            : HDTColors.s2,
                  ),
                ),
                child: Center(
                  child: i < step
                      ? const Icon(Icons.check,
                          size: 14, color: HDTColors.success)
                      : Text('${i + 1}',
                          style: HDTText.display(
                              size: 13,
                              color:
                                  i == step ? Colors.white : HDTColors.text3)),
                ),
              ),
              const SizedBox(height: HDTSpace.xs),
              Text(labels[i],
                  style: HDTText.overline(
                      size: 9,
                      color: i == step ? HDTColors.text : HDTColors.text3)),
            ],
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(
                    left: HDTSpace.sm, right: HDTSpace.sm, bottom: 20),
                color: i < step ? HDTColors.success : HDTColors.s2,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String step;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step, style: HDTText.overline(size: 10)),
        const SizedBox(height: HDTSpace.xs),
        Text(title, style: HDTText.display(size: 28)),
        const SizedBox(height: HDTSpace.sm),
        Text(subtitle, style: HDTText.body(color: HDTColors.text2)),
        const SizedBox(height: HDTSpace.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCols = constraints.maxWidth >= 680;
            return Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.lg,
              children: [
                for (final child in children)
                  SizedBox(
                    width: child is _Wide || !twoCols
                        ? constraints.maxWidth
                        : (constraints.maxWidth - HDTSpace.lg) / 2,
                    child: child,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Wide extends StatelessWidget {
  const _Wide({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: HDTSpace.xs),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: HDTText.body(size: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: 15),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: HDTSpace.xs),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          dropdownColor: HDTColors.s1,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: Text('Pilih...', style: HDTText.body(color: HDTColors.text3)),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _UploadMock extends StatelessWidget {
  const _UploadMock({
    required this.label,
    required this.hint,
    required this.uploaded,
    required this.onTap,
    this.optional = false,
  });

  final String label;
  final String hint;
  final bool uploaded;
  final bool optional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(optional ? '$label (OPSIONAL)' : label),
        const SizedBox(height: HDTSpace.xs),
        InkWell(
          borderRadius: HDTR.md,
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: HDTSpace.md),
            decoration: BoxDecoration(
              color: uploaded
                  ? HDTColors.success.withValues(alpha: 0.06)
                  : HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(
                color: uploaded ? HDTColors.success : HDTColors.s3,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle_outline : Icons.upload_file,
                  size: 17,
                  color: uploaded ? HDTColors.success : HDTColors.text3,
                ),
                const SizedBox(width: HDTSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uploaded ? 'File terupload' : 'Klik untuk upload',
                          style: HDTText.body(
                              size: 12,
                              color: uploaded
                                  ? HDTColors.success
                                  : HDTColors.text2)),
                      Text(hint, style: HDTText.mono(size: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: HDTR.lg,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Text(text,
                style: HDTText.body(color: HDTColors.text2, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.md),
        decoration: hdtCard(bg: HDTColors.bg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
                value: value, onChanged: (value) => onChanged(value ?? false)),
            const SizedBox(width: HDTSpace.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(text, style: HDTText.body(color: HDTColors.text2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: HDTSpace.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: HDTText.overline())),
          Expanded(
            child: Text(value.trim().isEmpty ? '-' : value,
                textAlign: TextAlign.right, style: HDTText.body()),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep(this.number, this.text);
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HDTSpace.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: HDTColors.s2,
              borderRadius: HDTR.sm,
            ),
            child:
                Center(child: Text(number, style: HDTText.display(size: 10))),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
              child: Text(text, style: HDTText.body(color: HDTColors.text2))),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.canBack,
    required this.busy,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final bool canBack;
  final bool busy;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: const BoxDecoration(
        color: HDTColors.bg,
        border: Border(top: BorderSide(color: HDTColors.s2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed:
                      canBack ? onBack : () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('BACK'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(busy ? 'MENGIRIM...' : nextLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: HDTText.overline(size: 9));
  }
}
