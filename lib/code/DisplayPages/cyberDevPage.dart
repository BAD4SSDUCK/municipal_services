import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

const String kColRoles = 'roles';
const String kColDepartments = 'departments';
const String kColDeptRoles = 'departmentRoles';
const String kColUsers = 'users';
const String kColNotifications = 'Notifications';
const String kColActionLogs = 'actionLogs';
const String kColCalendar = 'calendar';
const String kColEmployees = 'employees';
const String kColFaultReporting = 'faultReporting';
const String kColProperties = 'properties';
const String kColSuburbs = 'suburbs';

/// Keys used to persist the current "admin context" selection.
class AdminPrefsKeys {
  static const isLocalMunicipality = 'admin.isLocalMunicipality';
  static const districtId = 'admin.districtId';
  static const districtName = 'admin.districtName';
  static const municipalityId = 'admin.municipalityId';
  static const municipalityName = 'admin.municipalityName';

  /// Convenience: the Firestore base path you should prepend to admin ops.
  /// - local:      localMunicipalities/{municipalityId}
  /// - district:   districts/{districtId}/municipalities/{municipalityId}
  static const basePath = 'admin.basePath';
}

class AdminContext {
  final bool isLocalMunicipality;
  final String? districtId;
  final String? districtName;
  final String municipalityId;
  final String municipalityName;

  const AdminContext({
    required this.isLocalMunicipality,
    required this.municipalityId,
    required this.municipalityName,
    this.districtId,
    this.districtName,
  });

  String get basePath => isLocalMunicipality
      ? 'localMunicipalities/$municipalityId'
      : 'districts/$districtId/municipalities/$municipalityId';

  Map<String, String?> toPrefsMap() => {
        AdminPrefsKeys.isLocalMunicipality: isLocalMunicipality.toString(),
        AdminPrefsKeys.districtId: districtId,
        AdminPrefsKeys.districtName: districtName,
        AdminPrefsKeys.municipalityId: municipalityId,
        AdminPrefsKeys.municipalityName: municipalityName,
        AdminPrefsKeys.basePath: basePath,
      };

  static AdminContext? fromPrefs(SharedPreferences prefs) {
    final savedIsLocal =
        (prefs.getString(AdminPrefsKeys.isLocalMunicipality) ?? 'false') ==
            'true';
    final savedDistrictId = prefs.getString(AdminPrefsKeys.districtId);
    final savedDistrictName = prefs.getString(AdminPrefsKeys.districtName);
    final savedMunicipalityId = prefs.getString(AdminPrefsKeys.municipalityId);
    final savedMunicipalityName =
        prefs.getString(AdminPrefsKeys.municipalityName);

    if (savedMunicipalityId == null) return null;

    return AdminContext(
      isLocalMunicipality: savedIsLocal,
      districtId: savedIsLocal ? null : savedDistrictId,
      districtName:
          savedIsLocal ? null : (savedDistrictName ?? savedDistrictId),
      municipalityId: savedMunicipalityId,
      municipalityName: savedMunicipalityName ?? savedMunicipalityId,
    );
  }
}

enum ScopeKind { district, local }

/// Helper to scope all Firestore calls to the chosen basePath.
class AdminScopedCollection {
  final FirebaseFirestore fs;
  final AdminContext ctx;
  const AdminScopedCollection(this.fs, this.ctx);

  String path(String collection) => '${ctx.basePath}/$collection';
  CollectionReference<Map<String, dynamic>> col(String collection) =>
      fs.collection(path(collection));
  DocumentReference<Map<String, dynamic>> doc(String collection, String id) =>
      col(collection).doc(id);
}

class CyberfoxDevPage extends StatefulWidget {
  const CyberfoxDevPage({super.key});
  @override
  State<CyberfoxDevPage> createState() => _CyberfoxDevPageState();
}

class _DocItem {
  final String id;
  final String name;
  _DocItem(this.id, this.name);
}

class _CyberfoxDevPageState extends State<CyberfoxDevPage>
    with SingleTickerProviderStateMixin {
  final _fs = FirebaseFirestore.instance;

  ScopeKind _scope = ScopeKind.district;

  // District mode
  List<_DocItem> _districts = [];
  String? _selectedDistrictId;
  String? _selectedDistrictName;

  List<_DocItem> _districtMunicipalities = [];
  String? _selectedMunicipalityId;
  String? _selectedMunicipalityName;

  // Local mode
  List<_DocItem> _locals = [];
  String? _selectedLocalId;
  String? _selectedLocalName;

  bool _loading = true;
  String? _error;

  late final TabController _tabController;
  static const _tabs = <Tab>[
    Tab(text: 'Roles', icon: Icon(Icons.work_history)),
    Tab(text: 'Depts', icon: Icon(Icons.corporate_fare)),
    Tab(text: 'User List', icon: Icon(Icons.person_2_outlined)),
    Tab(text: 'Dept ↔ Role', icon: Icon(Icons.merge_type)),
    Tab(text: 'Version', icon: Icon(Icons.lock_open_outlined)),
    Tab(text: 'Municipalities', icon: Icon(Icons.location_city)),
    Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
    Tab(text: 'Action Logs', icon: Icon(Icons.list_alt)),
    Tab(text: 'Calendar', icon: Icon(Icons.calendar_month_outlined)),
    Tab(text: 'Employees', icon: Icon(Icons.person_3_outlined)),
    Tab(text: 'Fault Reporting', icon: Icon(Icons.report_problem_outlined)),
    Tab(text: 'Properties', icon: Icon(Icons.home_outlined)),
    Tab(text: 'Suburbs', icon: Icon(Icons.other_houses_outlined)),
  ];

  AdminContext? _activeContext;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {}); // <- forces FAB to rebuild for the new tab index
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeContext = AdminContext.fromPrefs(prefs);

      // Pre-fill pickers
      final savedIsLocal =
          (prefs.getString(AdminPrefsKeys.isLocalMunicipality) ?? 'false') ==
              'true';
      final savedDistrictId = prefs.getString(AdminPrefsKeys.districtId);
      final savedDistrictName = prefs.getString(AdminPrefsKeys.districtName);
      final savedMunicipalityId =
          prefs.getString(AdminPrefsKeys.municipalityId);
      final savedMunicipalityName =
          prefs.getString(AdminPrefsKeys.municipalityName);

      if (savedIsLocal) {
        _scope = ScopeKind.local;
        await _loadLocalMunicipalities();
        if (savedMunicipalityId != null) {
          _selectedLocalId = savedMunicipalityId;
          _selectedLocalName = savedMunicipalityName ?? savedMunicipalityId;
        }
      } else {
        _scope = ScopeKind.district;
        await _loadDistricts();
        if (savedDistrictId != null) {
          _selectedDistrictId = savedDistrictId;
          _selectedDistrictName = savedDistrictName ?? savedDistrictId;
          await _loadDistrictMunicipalities(savedDistrictId);
        }
        if (savedMunicipalityId != null) {
          _selectedMunicipalityId = savedMunicipalityId;
          _selectedMunicipalityName =
              savedMunicipalityName ?? savedMunicipalityId;
        }
      }
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDistricts() async {
    _districts = [];
    _selectedDistrictId = null;
    _selectedDistrictName = null;
    _districtMunicipalities = [];
    _selectedMunicipalityId = null;
    _selectedMunicipalityName = null;

    final snap = await _fs.collection('districts').get();
    _districts = snap.docs.map((d) {
      final data = (d.data() as Map<String, dynamic>?);
      final name = (data?['name'] as String?)?.trim();
      return _DocItem(d.id, (name?.isNotEmpty ?? false) ? name! : d.id);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _loadDistrictMunicipalities(String districtId) async {
    _districtMunicipalities = [];
    _selectedMunicipalityId = null;
    _selectedMunicipalityName = null;

    final snap = await _fs
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .get();

    _districtMunicipalities = snap.docs.map((d) {
      final data = (d.data() as Map<String, dynamic>?);
      final name = (data?['name'] as String?)?.trim();
      return _DocItem(d.id, (name?.isNotEmpty ?? false) ? name! : d.id);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _loadLocalMunicipalities() async {
    _locals = [];
    _selectedLocalId = null;
    _selectedLocalName = null;

    final snap = await _fs.collection('localMunicipalities').get();
    _locals = snap.docs.map((d) {
      final data = (d.data() as Map<String, dynamic>?);
      final name = (data?['name'] as String?)?.trim();
      return _DocItem(d.id, (name?.isNotEmpty ?? false) ? name! : d.id);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  AdminContext? _buildContextFromPickers() {
    if (_scope == ScopeKind.district) {
      if (_selectedDistrictId == null || _selectedMunicipalityId == null) {
        return null;
      }
      return AdminContext(
        isLocalMunicipality: false,
        districtId: _selectedDistrictId!,
        districtName: _selectedDistrictName ?? _selectedDistrictId!,
        municipalityId: _selectedMunicipalityId!,
        municipalityName: _selectedMunicipalityName ?? _selectedMunicipalityId!,
      );
    } else {
      if (_selectedLocalId == null) return null;
      return AdminContext(
        isLocalMunicipality: true,
        municipalityId: _selectedLocalId!,
        municipalityName: _selectedLocalName ?? _selectedLocalId!,
      );
    }
  }

  Future<void> _saveContext() async {
    final ctx = _buildContextFromPickers();
    if (ctx == null) {
      _snack(_scope == ScopeKind.local
          ? 'Please select a local municipality.'
          : 'Please select both the district and the municipality.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final map = ctx.toPrefsMap();
    for (final entry in map.entries) {
      if (entry.key == AdminPrefsKeys.isLocalMunicipality) {
        await prefs.setString(entry.key, entry.value ?? 'false');
      } else {
        if (entry.value == null) {
          await prefs.remove(entry.key);
        } else {
          await prefs.setString(entry.key, entry.value!);
        }
      }
    }
    if (mounted) {
      setState(() {
        _activeContext = ctx; // enable tabs
      });
    }
    _snack('Context saved: ${ctx.basePath}');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _scopeSelector() {
    return SegmentedButton<ScopeKind>(
      segments: const [
        ButtonSegment(
            value: ScopeKind.district,
            label: Text('District'),
            icon: Icon(Icons.apartment)),
        ButtonSegment(
            value: ScopeKind.local,
            label: Text('Local'),
            icon: Icon(Icons.location_city)),
      ],
      selected: <ScopeKind>{_scope},
      onSelectionChanged: (s) async {
        final next = s.first;
        if (next == _scope) return;
        if (mounted) {
          setState(() {
            _scope = next;
            _loading = true;
            _error = null;
            _activeContext = null; // force re-save
          });
        }
        try {
          if (_scope == ScopeKind.district) {
            await _loadDistricts();
          } else {
            await _loadLocalMunicipalities();
          }
        } catch (e) {
          _error = 'Failed to load: $e';
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
    );
  }

  Widget _districtPickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Select District',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            IconButton(
              tooltip: 'Create District',
              icon: const Icon(
                Icons.add,
                color: Colors.green,
              ),
              onPressed: () => _openDistrictSheet(),
            ),
            IconButton(
              tooltip: 'Edit District',
              icon: const Icon(Icons.edit),
              onPressed: (_selectedDistrictId == null)
                  ? null
                  : () => _openDistrictSheet(
                        districtId: _selectedDistrictId!,
                        districtName: _selectedDistrictName,
                      ),
            ),
            IconButton(
              tooltip: 'Delete District',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: (_selectedDistrictId == null)
                  ? null
                  : () => _deleteDistrict(_selectedDistrictId!),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---- District dropdown ----
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          value: _selectedDistrictId,
          items: _districts
              .map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text('${d.name}  (${d.id})'),
                  ))
              .toList(),
          onChanged: (val) async {
            if (val == null) return;
            if (mounted) {
              setState(() {
                _selectedDistrictId = val;
                _selectedDistrictName =
                    _districts.firstWhere((x) => x.id == val).name;
                _loading = true;
                _districtMunicipalities = [];
                _selectedMunicipalityId = null;
                _selectedMunicipalityName = null;
              });
            }
            try {
              await _loadDistrictMunicipalities(val);
            } catch (e) {
              _error = 'Failed to load municipalities: $e';
            } finally {
              if (mounted) setState(() => _loading = false);
            }
          },
        ),

        const SizedBox(height: 16),
        const Text('Select Municipality',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),

        if (_selectedDistrictId == null)
          const Text(
            'Pick a district first.',
            style: TextStyle(color: Colors.black),
          )
        else if (_districtMunicipalities.isEmpty) ...[
          // No municipalities yet — offer to create the first one
          OutlinedButton.icon(
            icon: const Icon(Icons.business_rounded),
            label: const Text(
              'Create first municipality',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () async {
              final ref = MunicipalitiesTab.refForContextOrSelection(
                FirebaseFirestore.instance,
                scope: ScopeKind.district,
                districtId: _selectedDistrictId,
              );
              if (ref == null) return;
              await MunicipalitiesTab.openMunicipalitySheet(context, ref);
              // reload list after creation
              if (mounted) {
                setState(() => _loading = true);
              }
              try {
                await _loadDistrictMunicipalities(_selectedDistrictId!);
              } catch (e) {
                _error = 'Failed to load municipalities: $e';
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ] else
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            value: _selectedMunicipalityId,
            items: _districtMunicipalities
                .map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.name}  (${m.id})'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              if (mounted) {
                setState(() {
                  _selectedMunicipalityId = val;
                  _selectedMunicipalityName = _districtMunicipalities
                      .firstWhere((x) => x.id == val)
                      .name;
                });
              }
            },
          ),
      ],
    );
  }

  Widget _localPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Local Municipality',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        value: _selectedLocalId,
        dropdownColor: Colors.black,
        items: _locals
            .map((m) => DropdownMenuItem(
                value: m.id, child: Text('${m.name}  (${m.id})')))
            .toList(),
        onChanged: (val) {
          if (val == null) return;
          if (mounted) {
            setState(() {
              _selectedLocalId = val;
              _selectedLocalName = _locals.firstWhere((x) => x.id == val).name;
              _activeContext = null;
            });
          }
        },
      ),
    ]);
  }

  Future<void> _openDistrictSheet(
      {String? districtId, String? districtName}) async {
    final idCtrl = TextEditingController(text: districtId ?? '');
    final nameCtrl = TextEditingController(text: districtName ?? '');

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    districtId == null ? 'Create District' : 'Edit District',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                if (districtId == null) ...[
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                        labelText: 'District ID *',
                        helperText:
                            'Used as the document ID (e.g. "uMgungundlovu")',
                        labelStyle: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text('ID: $districtId',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Display Name (optional)',
                      labelStyle: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final id = (districtId ?? idCtrl.text).trim();
                    final name = nameCtrl.text.trim();
                    if (id.isEmpty) return;

                    final payload = <String, dynamic>{
                      if (name.isNotEmpty) 'name': name,
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (districtId == null)
                        'createdAt': FieldValue.serverTimestamp(),
                    };

                    await _fs.collection('districts').doc(id).set(
                          payload,
                          SetOptions(merge: true),
                        );

                    // refresh lists & preselect the (new/edited) district
                    await _loadDistricts();
                    if (!mounted) return;
                    setState(() {
                      _selectedDistrictId = id;
                      _selectedDistrictName = name.isNotEmpty ? name : id;
                    });

                    if (mounted) {
                      Navigator.of(ctx).pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('District saved.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmCascadeDeleteDistrict(String label) async {
    bool cascade = true;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(
            'Delete District',
            style: TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete "$label"?',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: cascade,
                checkColor: Colors.black,
                activeColor: Colors.black,
                onChanged: (v) => setState(() => cascade = v ?? true),
                title: const Text(
                  'Also delete all subcollections (municipalities, users, etc.)',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                )),
            TextButton(
                onPressed: () => Navigator.pop(ctx, cascade),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.black),
                )),
          ],
        ),
      ),
    );
  }

// --- Delete District (single doc or recursive via callable) ---
  Future<void> _deleteDistrict(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final label = _selectedDistrictName ?? id;
    final choice = await _confirmCascadeDeleteDistrict(label);
    if (choice == null) return; // cancelled

    try {
      if (choice) {
        // Recursive delete ENTIRE district tree
        final functions = FirebaseFunctions.instanceFor(
            region: 'europe-west1'); // <- your region
        await functions.httpsCallable('deleteMunicipalityRecursive').call({
          'basePath': 'districts/$id',
        });
      } else {
        // Only delete the district doc; subcollections remain
        await _fs.collection('districts').doc(id).delete();
      }

      // reload & clear current selection
      await _loadDistricts();
      if (!mounted) return;
      setState(() {
        _selectedDistrictId = null;
        _selectedDistrictName = null;
        _districtMunicipalities = [];
        _selectedMunicipalityId = null;
        _selectedMunicipalityName = null;
      });

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(choice
                ? 'District "$label" and nested data deleted.'
                : 'District "$label" deleted (nested data kept).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete district: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePathPreview = () {
      if (_scope == ScopeKind.district) {
        if (_selectedDistrictId != null && _selectedMunicipalityId != null) {
          return 'districts/$_selectedDistrictId/municipalities/$_selectedMunicipalityId';
        }
      } else {
        if (_selectedLocalId != null) {
          return 'localMunicipalities/$_selectedLocalId';
        }
      }
      return '—';
    }();
    final tabsEnabled = _activeContext != null;
    final bool hasDistrictSelection =
        _scope == ScopeKind.district && _selectedDistrictId != null;

    final bool muniTabEnabled =
        tabsEnabled || _scope == ScopeKind.local || hasDistrictSelection;

// Precompute scoped refs for the FAB row
    CollectionReference<Map<String, dynamic>>? _rolesRef;
    CollectionReference<Map<String, dynamic>>? _deptsRef;
    CollectionReference<Map<String, dynamic>>? _linksRef;
    CollectionReference<Map<String, dynamic>>? _usersRef;
    CollectionReference<Map<String, dynamic>>? _notifsRef;
    if (tabsEnabled) {
      final scoped = AdminScopedCollection(_fs, _activeContext!);
      _rolesRef = scoped.col(kColRoles);
      _deptsRef = scoped.col(kColDepartments);
      _linksRef = scoped.col(kColDeptRoles);
      _usersRef = scoped.col(kColUsers);
      _notifsRef = scoped.col(kColNotifications);
    }

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Cyberfox Admin Config Page',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (_) => setState(() {}),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _scopeSelector(),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red))),
                        _scope == ScopeKind.district
                            ? _districtPickers()
                            : _localPicker(),
                        const SizedBox(height: 8),
                        ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Base Path Preview'),
                            subtitle: Text(basePathPreview,
                                style:
                                    const TextStyle(fontFamily: 'monospace')),
                            trailing: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Use this context',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: _saveContext)),
                        if (!tabsEnabled)
                          const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                  'Select a municipality and tap "Use this context" to enable the tabs.',
                                  style: TextStyle(color: Colors.black),
                                ))
                              ])),
                      ])),
              const Divider(height: 1),
              Expanded(
                  child: TabBarView(controller: _tabController, children: [
                if (tabsEnabled)
                  RolesTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  DepartmentsTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  UsersTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  DeptRolesTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  VersionTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (muniTabEnabled)
                  MunicipalitiesTab(
                    scope: _scope,
                    contextData: _activeContext, // may be null
                    districtId:
                        _selectedDistrictId, // used when context is null
                  )
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  NotificationsTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  ActionLogsTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  CalendarTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  EmployeesTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  FaultReportingTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  PropertiesTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
                if (tabsEnabled)
                  SuburbsTab(contextData: _activeContext!)
                else
                  const _DisabledTabMessage(),
              ])),
            ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (!tabsEnabled)
          ? null
          : (() {
              switch (_tabController.index) {
                case 0: // Roles tab
                  return FloatingActionButton(
                    heroTag: 'fabRoles',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_moderator),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      RolesTab._openRoleSheet(context, scoped.col(kColRoles));
                    },
                  );
                case 1: // Departments tab
                  return FloatingActionButton(
                    heroTag: 'fabDepts',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.business),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      DepartmentsTab._openDeptSheet(
                          context, scoped.col(kColDepartments));
                    },
                  );
                case 2: // Departments tab
                  return FloatingActionButton(
                    heroTag: 'fabUsers',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.account_box),
                    onPressed: () => UsersTab._openUserSheet(
                      context,
                      _usersRef!, // users
                      _rolesRef!, // roles
                      _deptsRef!, // departments
                      _activeContext!, // AdminContext
                    ),
                  );
                case 3: // Departments tab
                  return FloatingActionButton(
                    heroTag: 'fabLink',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.account_tree),
                    onPressed: () => DeptRolesTab._openLinkSheet(
                      context,
                      _linksRef!, // deptRoles
                      _deptsRef!, // departments
                      _rolesRef!, // roles
                    ),
                  );
                case 5:
                  if (!muniTabEnabled)
                    return null; // allow with only district selection
                  final ref = MunicipalitiesTab.refForContextOrSelection(
                    FirebaseFirestore.instance,
                    ctx: _activeContext, // may be null
                    scope: _scope,
                    districtId: _selectedDistrictId,
                  );
                  if (ref == null) return null;
                  return FloatingActionButton(
                    heroTag: 'fabMunicipality',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.business_rounded),
                    onPressed: () => MunicipalitiesTab.openMunicipalitySheet(
                      context,
                      ref,
                    ),
                  );
                case 6: // Departments tab
                  return FloatingActionButton(
                    heroTag: 'fabNotif',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_alert),
                    onPressed: () => NotificationsTab.openNotificationSheet(
                        context, _notifsRef! // roles
                        ),
                  );
                case 8:
                  return FloatingActionButton(
                    heroTag: 'fabCalendar',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.calendar_month),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      CalendarTab.openEventSheet(
                          context, scoped.col(kColCalendar));
                    },
                  );
                case 9:
                  return FloatingActionButton(
                    heroTag: 'fabEmployees',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.person_add),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      EmployeesTab.openEmployeeSheet(
                          context, scoped.col(kColEmployees));
                    },
                  );
                case 10:
                  if (!tabsEnabled) return null;
                  return FloatingActionButton(
                    heroTag: 'fabFaults',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      FaultReportingTab.openFaultSheet(
                          context, scoped.col(kColFaultReporting));
                    },
                  );
                case 11:
                  if (!tabsEnabled) return null;
                  return FloatingActionButton(
                    heroTag: 'fabProps',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_home),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      PropertiesTab.openPropertySheet(
                          context, scoped.col(kColProperties), _activeContext!);
                    },
                  );
                case 12:
                  return FloatingActionButton(
                    heroTag: 'fabSuburbs',
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_location_alt),
                    onPressed: () {
                      final scoped =
                          AdminScopedCollection(_fs, _activeContext!);
                      SuburbsTab._openSuburbSheet(
                          context, scoped.col(kColSuburbs), _activeContext!);
                    },
                  );
                default:
                  return null; // no FAB on other tabs (for now)
              }
            })(),
    );
  }
}

class _DisabledTabMessage extends StatelessWidget {
  const _DisabledTabMessage();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No context selected.\nPick a municipality and tap "Use this context".',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

// ======================= ROLES TAB =======================
class RolesTab extends StatelessWidget {
  final AdminContext contextData;
  const RolesTab({super.key, required this.contextData});

  static Future<void> _openRoleSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> rolesRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final ctrl =
        TextEditingController(text: existing?['role'] as String? ?? '');
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    docId == null ? 'Create Role' : 'Edit Role',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                        labelText: 'Role *',
                        labelStyle: TextStyle(color: Colors.black))),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final roleName = ctrl.text.trim();
                    if (roleName.isEmpty) return;
                    final payload = {'role': roleName};
                    if (docId == null) {
                      await rolesRef.add(payload);
                    } else {
                      await rolesRef
                          .doc(docId)
                          .set(payload, SetOptions(merge: true));
                    }
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final rolesRef = scoped.col(kColRoles);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: rolesRef.orderBy('role').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No roles found for this municipality.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Path: ${rolesRef.path}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Create first role',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () => _openRoleSheet(context, rolesRef),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final roleName = (d.data()['role'] as String?) ?? '(unnamed)';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.work_history),
                  title: Text(roleName),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => _openRoleSheet(context, rolesRef,
                            docId: d.id, existing: d.data()),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await _confirm(
                              context, 'Delete role "$roleName"?');
                          if (ok) await rolesRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =================== DEPARTMENTS TAB ===================
class DepartmentsTab extends StatelessWidget {
  final AdminContext contextData;
  const DepartmentsTab({super.key, required this.contextData});

  // create / edit bottom sheet
  static Future<void> _openDeptSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> deptsRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final ctrl =
        TextEditingController(text: existing?['deptName'] as String? ?? '');

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    docId == null ? 'Create Department' : 'Edit Department',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                      labelText: 'Department *',
                      labelStyle: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    final payload = {
                      'deptName': name,
                      'official': true,
                    };
                    if (docId == null) {
                      await deptsRef.add(payload);
                    } else {
                      await deptsRef
                          .doc(docId)
                          .set(payload, SetOptions(merge: true));
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final deptsRef = scoped.col(kColDepartments); // 'deptInfo'

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: deptsRef.orderBy('deptName').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No departments found for this municipality.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Path: ${deptsRef.path}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Create first department',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () => _openDeptSheet(context, deptsRef),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final name = (d.data()['deptName'] as String?) ?? '(unnamed)';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Departments Information',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.business),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Department: $name')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            // Delete
                            Material(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () async {
                                  final ok = await _confirm(
                                      context, 'Delete this Department?');
                                  if (ok) await deptsRef.doc(d.id).delete();
                                },
                                borderRadius: BorderRadius.circular(32),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Text(
                                    'Delete Department',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Edit
                            Material(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _openDeptSheet(context, deptsRef,
                                    docId: d.id, existing: d.data()),
                                borderRadius: BorderRadius.circular(32),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Text(
                                    '  Edit Department  ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =================== DEPT ↔ ROLE TAB ===================
class DeptRolesTab extends StatelessWidget {
  final AdminContext contextData;
  const DeptRolesTab({super.key, required this.contextData});
  static Future<void> _openLinkSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> links,
    CollectionReference<Map<String, dynamic>> depts,
    CollectionReference<Map<String, dynamic>> roles, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    String? selectedDept = existing?['deptName'] as String?;
    String? selectedRole = existing?['userRole'] as String?;
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (ctx) {
          return SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: StatefulBuilder(builder: (context, setState) {
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Text(
                                  docId == null
                                      ? 'Link Department to Role'
                                      : 'Edit Dept ↔ Role Link',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black))),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: depts.orderBy('deptName').snapshots(),
                            builder: (context, snap) {
                              final items = [
                                for (final d in (snap.data?.docs ??
                                    <QueryDocumentSnapshot<
                                        Map<String, dynamic>>>[]))
                                  (d.data()['deptName'] as String?)?.trim() ??
                                      ''
                              ].where((e) => e.isNotEmpty).toSet().toList()
                                ..sort();
                              return DropdownButtonFormField<String>(
                                  value: selectedDept,
                                  items: [
                                    for (final v in items)
                                      DropdownMenuItem(value: v, child: Text(v))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => selectedDept = v),
                                  decoration: const InputDecoration(
                                      labelText: 'Department *',
                                      labelStyle:
                                          TextStyle(color: Colors.black)),
                                  isExpanded: true);
                            },
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: roles.orderBy('role').snapshots(),
                            builder: (context, snap) {
                              final items = [
                                for (final d in (snap.data?.docs ??
                                    <QueryDocumentSnapshot<
                                        Map<String, dynamic>>>[]))
                                  (d.data()['role'] as String?)?.trim() ?? ''
                              ].where((e) => e.isNotEmpty).toSet().toList()
                                ..sort();
                              return DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  items: [
                                    for (final v in items)
                                      DropdownMenuItem(value: v, child: Text(v))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => selectedRole = v),
                                  decoration: const InputDecoration(
                                      labelText: 'Role *',
                                      labelStyle:
                                          TextStyle(color: Colors.black)),
                                  isExpanded: true);
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              child: const Text('Save'),
                              onPressed: () async {
                                if ((selectedDept ?? '').isEmpty ||
                                    (selectedRole ?? '').isEmpty) return;
                                final payload = {
                                  'deptName': selectedDept,
                                  'userRole': selectedRole,
                                  'official': true
                                };
                                if (docId == null) {
                                  await links.add(payload);
                                } else {
                                  await links
                                      .doc(docId)
                                      .set(payload, SetOptions(merge: true));
                                }
                                Navigator.of(ctx).pop();
                              })
                        ]);
                  })));
        });
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final linkRef = scoped.col(kColDeptRoles);
    final deptsRef = scoped.col(kColDepartments);
    final rolesRef = scoped.col(kColRoles);
    return Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: linkRef.orderBy('deptName').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No department roles found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Path: ${linkRef.path}',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.green,
                          ),
                          label: const Text(
                            'Create first department role',
                            style: TextStyle(color: Colors.black),
                          ),
                          onPressed: () => _openLinkSheet(
                              context, linkRef, deptsRef, rolesRef),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final dept = (d.data()['deptName'] as String?) ?? '';
                final role = (d.data()['userRole'] as String?) ?? '';
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                              child: Text('Department ↔ Role Links',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700))),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.business),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Department: $dept'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.badge),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Role: $role'))
                          ]),
                          const SizedBox(height: 16),
                          Center(
                              child: Column(children: [
                            Material(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () async {
                                    final ok = await _confirm(
                                        context, 'Delete link $dept ↔ $role?');
                                    if (ok) await linkRef.doc(d.id).delete();
                                  },
                                  borderRadius: BorderRadius.circular(32),
                                  child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Text('Delete Link',
                                          style:
                                              TextStyle(color: Colors.white))),
                                )),
                            const SizedBox(height: 10),
                            Material(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _openLinkSheet(
                                      context, linkRef, deptsRef, rolesRef,
                                      docId: d.id, existing: d.data()),
                                  borderRadius: BorderRadius.circular(32),
                                  child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Text('Edit Link',
                                          style:
                                              TextStyle(color: Colors.white))),
                                )),
                          ])),
                        ]),
                  ),
                );
              },
            );
          },
        ));
  }
}

// ======================= USERS TAB =======================
class UsersTab extends StatelessWidget {
  final AdminContext contextData;
  const UsersTab({super.key, required this.contextData});
  static Future<void> _openUserSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> usersRef,
    CollectionReference<Map<String, dynamic>> rolesRef,
    CollectionReference<Map<String, dynamic>> deptsRef,
    AdminContext ctx, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final userNameCtrl =
        TextEditingController(text: existing?['userName'] as String? ?? '');
    final firstCtrl =
        TextEditingController(text: existing?['firstName'] as String? ?? '');
    final lastCtrl =
        TextEditingController(text: existing?['lastName'] as String? ?? '');
    final emailCtrl =
        TextEditingController(text: existing?['email'] as String? ?? '');
    final existingPhoneRaw = (existing?['cellNumber'] as String?) ?? '';
    String _toLocalDigits(String raw) {
      // Strip everything to digits
      var d = raw.replaceAll(RegExp(r'\D'), '');
      // If prefixed with country code, drop it
      if (d.startsWith('27')) d = d.substring(2);
      // If user saved a local "0..." previously, drop that leading 0 for E.164 UX
      if (d.startsWith('0')) d = d.substring(1);
      return d; // local digits only, e.g. "821234567"
    }

    final localPhoneCtrl =
        TextEditingController(text: _toLocalDigits(existingPhoneRaw));
    final passwordCtrl = TextEditingController();
    String? selectedRole = existing?['userRole'] as String?;
    String? selectedDept = existing?['deptName'] as String?;
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (ctxSheet) {
          return SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(ctxSheet).viewInsets.bottom + 20),
                  child: StatefulBuilder(builder: (context, setState) {
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Text(
                                  docId == null
                                      ? 'Create New Official User'
                                      : 'Edit Official User',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black))),
                          const SizedBox(height: 12),
                          TextField(
                              controller: userNameCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'User Name',
                                  labelStyle: TextStyle(color: Colors.black))),
                          const SizedBox(height: 8),
                          TextField(
                              controller: firstCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  labelStyle: TextStyle(color: Colors.black))),
                          const SizedBox(height: 8),
                          TextField(
                              controller: lastCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  labelStyle: TextStyle(color: Colors.black))),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: deptsRef.orderBy('deptName').snapshots(),
                            builder: (context, snap) {
                              final items = [
                                for (final d in (snap.data?.docs ??
                                    <QueryDocumentSnapshot<
                                        Map<String, dynamic>>>[]))
                                  (d.data()['deptName'] as String?)?.trim() ??
                                      ''
                              ].where((e) => e.isNotEmpty).toSet().toList()
                                ..sort();
                              return DropdownButtonFormField<String>(
                                  value: selectedDept,
                                  items: [
                                    for (final v in items)
                                      DropdownMenuItem(value: v, child: Text(v))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => selectedDept = v),
                                  decoration: const InputDecoration(
                                      labelText: 'User Department',
                                      labelStyle:
                                          TextStyle(color: Colors.black)));
                            },
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: rolesRef.orderBy('role').snapshots(),
                            builder: (context, snap) {
                              final items = [
                                for (final d in (snap.data?.docs ??
                                    <QueryDocumentSnapshot<
                                        Map<String, dynamic>>>[]))
                                  (d.data()['role'] as String?)?.trim() ?? ''
                              ].where((e) => e.isNotEmpty).toSet().toList()
                                ..sort();
                              return DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  items: [
                                    for (final v in items)
                                      DropdownMenuItem(value: v, child: Text(v))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => selectedRole = v),
                                  decoration: const InputDecoration(
                                      labelText: 'User Role',
                                      labelStyle:
                                          TextStyle(color: Colors.black)));
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                              controller: emailCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'User Email',
                                  labelStyle: TextStyle(color: Colors.black))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: localPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              // Shows +27 visually; user types the remaining digits
                              prefixText: '+27 ',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // TextField(
                          //     controller: passwordCtrl,
                          //     obscureText: true,
                          //     decoration: const InputDecoration(
                          //         labelText:
                          //             'User Password (optional — for CF provisioning)')),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: () async {
                                String localDigits = localPhoneCtrl.text
                                    .replaceAll(RegExp(r'\D'), '');
                                if (localDigits.startsWith('0')) {
                                  // Normalize local "0..." to E.164 by dropping the 0
                                  localDigits = localDigits.substring(1);
                                }
                                final phoneE164 = localDigits.isEmpty
                                    ? ''
                                    : '+27$localDigits';

                                final payload = <String, dynamic>{
                                  'userName': userNameCtrl.text.trim(),
                                  'deptName': selectedDept,
                                  'userRole': selectedRole,
                                  'firstName': firstCtrl.text.trim(),
                                  'lastName': lastCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'cellNumber': phoneE164,
                                  'official': true,
                                  'isLocalMunicipality':
                                      ctx.isLocalMunicipality,
                                  'isLocalUser': ctx.isLocalMunicipality,
                                  'districtId': ctx.isLocalMunicipality
                                      ? null
                                      : ctx.districtId,
                                  'municipalityId': ctx.municipalityId,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };
                                // final pwd = passwordCtrl.text.trim();
                                // if (pwd.isNotEmpty) {
                                //   payload['password'] =
                                //       pwd; // for CF provisioning if used
                                // }
                                if (localDigits.length != 9) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Enter a valid SA number (9 digits after +27).')),
                                  );
                                  return;
                                }

                                if (docId == null) {
                                  payload['createdAt'] =
                                      FieldValue.serverTimestamp();
                                  await usersRef.add(payload);
                                } else {
                                  await usersRef
                                      .doc(docId)
                                      .set(payload, SetOptions(merge: true));
                                }
                                Navigator.of(ctxSheet).pop();
                              })
                        ]);
                  })));
        });
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final usersRef = scoped.col(kColUsers);
    final rolesRef = scoped.col(kColRoles);
    final deptsRef = scoped.col(kColDepartments);
    return Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: usersRef.orderBy('deptName').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No users found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Path: ${usersRef.path}',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.green,
                          ),
                          label: const Text(
                            'Create first user',
                            style: TextStyle(color: Colors.black),
                          ),
                          onPressed: () => _openUserSheet(
                            context,
                            usersRef,
                            rolesRef,
                            deptsRef,
                            contextData,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();
                final userName = (data['userName'] as String?) ?? '';
                final dept = (data['deptName'] as String?) ?? '';
                final role = (data['userRole'] as String?) ?? '';
                final first = (data['firstName'] as String?) ?? '';
                final last = (data['lastName'] as String?) ?? '';
                final email = (data['email'] as String?) ?? '';
                final phone = (data['cellNumber'] as String?) ?? '';
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                              child: Text('Official User Information',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700))),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.switch_account),
                            const SizedBox(width: 8),
                            Expanded(child: Text('User Name: $userName'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.business_center),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Department: $dept'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.badge),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Role: $role'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.account_circle),
                            const SizedBox(width: 8),
                            Expanded(child: Text('First Name: $first'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.account_circle),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Last Name: $last'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.email),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Email: $email'))
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.phone),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Phone Number: $phone'))
                          ]),
                          const SizedBox(height: 16),
                          Center(
                              child: Column(children: [
                            Material(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () async {
                                    final ok = await _confirm(
                                        context, 'Delete this user?');
                                    if (ok) await usersRef.doc(d.id).delete();
                                  },
                                  borderRadius: BorderRadius.circular(32),
                                  child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Text('  Delete User  ',
                                          style:
                                              TextStyle(color: Colors.white))),
                                )),
                            const SizedBox(height: 10),
                            Material(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _openUserSheet(context, usersRef,
                                      rolesRef, deptsRef, contextData,
                                      docId: d.id, existing: data),
                                  borderRadius: BorderRadius.circular(32),
                                  child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Text('Edit User Info',
                                          style:
                                              TextStyle(color: Colors.white))),
                                )),
                          ])),
                        ]),
                  ),
                );
              },
            );
          },
        ));
  }
}

//=================Version Tab=======================
class _VersionOption {
  final String id;
  final String version;
  const _VersionOption({required this.id, required this.version});
}

class VersionTab extends StatelessWidget {
  final AdminContext contextData;
  const VersionTab({super.key, required this.contextData});

  String _tierFromVersion(String v) {
    final s = v.toLowerCase().trim();
    if (s.contains('Unpaid') || s.contains('Free') || s.contains('Basic')) {
      return 'Unpaid';
    }
    if (s.contains('Premium')) return 'Premium';
    if (s.contains('Paid')) return 'Paid';
    return s; // fallback
  }

  static String _cap(String t) =>
      t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}';

  static Future<void> _createDefaults(
    CollectionReference<Map<String, dynamic>> versionsCol,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final v in const ['Paid', 'Unpaid', 'Premium']) {
      final doc = versionsCol.doc(); // auto-id
      batch.set(doc, {'version': v, 'createdAt': FieldValue.serverTimestamp()});
    }

    await batch.commit();

    // Ensure the parent 'current' document exists in the console
    await versionsCol.doc('current').set(
      {
        'version':
            'Premium', // or 'premium' — whatever label you prefer to seed
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> _openOptionSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> versionsCol, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final ctrl =
        TextEditingController(text: (existing?['version'] as String?) ?? '');
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    docId == null
                        ? 'Create Version Option'
                        : 'Edit Version Option',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                      labelText: 'Version label (e.g. Paid / Unpaid / Premium)',
                      labelStyle: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final v = ctrl.text.trim();
                    if (v.isEmpty) return;
                    final payload = {
                      'version': v,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (docId == null) {
                      await versionsCol.add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await versionsCol
                          .doc(docId)
                          .set(payload, SetOptions(merge: true));
                    }
                    if (context.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final scoped = AdminScopedCollection(fs, contextData);

    final versionsCol = scoped.col('version'); // <basePath>/version
    final currentDoc = versionsCol
        .doc('current')
        .collection('current-version')
        .doc('current'); // .../current/current-version/current
    final ButtonStyle style = ElevatedButton.styleFrom(
        textStyle: const TextStyle(color: Colors.black),
        foregroundColor: Colors.black);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: versionsCol.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          // Build options from auto-id docs (skip 'current')
          final rawDocs = (snap.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .where((d) => d.id != 'current')
              .toList();

          final Map<String, _VersionOption> options =
              <String, _VersionOption>{}; // key = normalized tier
          for (final d in rawDocs) {
            final ver = (d.data()['version'] as String?)?.trim();
            if (ver == null || ver.isEmpty) continue;
            final tier = _tierFromVersion(ver);
            options[tier] = _VersionOption(id: d.id, version: ver);
          }

          if (options.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No version options found for this municipality.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Path: ${versionsCol.path}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.auto_fix_high,
                              color: Colors.green,
                            ),
                            label: const Text('Create default options'),
                            onPressed: () async => _createDefaults(versionsCol),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.green,
                            ),
                            label: const Text('Add custom option'),
                            onPressed: () =>
                                _openOptionSheet(context, versionsCol),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Order: Paid, Unpaid, Premium, then the rest
          final preferred = ['Paid', 'Unpaid', 'Premium'];
          final tiers = [
            ...preferred.where(options.containsKey),
            ...options.keys.where((t) => !preferred.contains(t)),
          ];

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: currentDoc.snapshots(),
            builder: (context, curSnap) {
              final cur = curSnap.data?.data();
              final currentVersion = (cur?['version'] as String?)?.trim();
              final currentTier = currentVersion == null
                  ? null
                  : _tierFromVersion(currentVersion);

              String selectedTier = currentTier ?? tiers.first;
              String selectedVersion = options[selectedTier]!.version;

              return StatefulBuilder(
                builder: (context, setState) {
                  Future<void> _save() async {
                    final parentCurrentRef = versionsCol.doc('current');

                    // 1) Upsert the parent doc so it exists and shows a field in the console
                    await parentCurrentRef.set(
                      {
                        'version': selectedVersion,
                        'tier': selectedTier,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );

                    // 2) Upsert the subdocument you already use
                    await currentDoc.set(
                      {
                        'version': selectedVersion,
                        'tier': selectedTier,
                        'sourceDocId': options[selectedTier]!.id,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Version set to $selectedVersion (${_cap(selectedTier)})'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current: ${currentVersion ?? 'Not set'}'
                                '${currentTier != null ? ' ($currentTier)' : ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          const Text('Select a version',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          const SizedBox(height: 8),

                          // Radio buttons for each option
                          ...tiers.map((t) => RadioListTile<String>(
                                dense: true,
                                value: t,
                                groupValue: selectedTier,
                                selectedTileColor: Colors.black,
                                activeColor: Colors.black,
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    selectedTier = v;
                                    selectedVersion = options[v]!.version;
                                  });
                                },
                                title: Text(
                                    '${t[0].toUpperCase()}${t.substring(1)}'),
                                // subtitle: Text(options[t]!.version),
                              )),

                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Set Current Version'),
                            onPressed: _save,
                            style: style,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

//==============Municipalities Tab=================
class MunicipalitiesTab extends StatelessWidget {
  final AdminContext? contextData;
  final ScopeKind scope;
  final String? districtId;
  const MunicipalitiesTab(
      {super.key, this.contextData, required this.scope, this.districtId});

  // Where to read/write municipalities for the current context
  static CollectionReference<Map<String, dynamic>>? refForContext(
    FirebaseFirestore fs,
    AdminContext ctx,
  ) {
    if (ctx.isLocalMunicipality) {
      // Superadmin manages the global localMunicipalities list
      return fs.collection('localMunicipalities');
    } else {
      if (ctx.districtId == null || ctx.districtId!.isEmpty) return null;
      return fs
          .collection('districts')
          .doc(ctx.districtId!)
          .collection('municipalities');
    }
  }

  static CollectionReference<Map<String, dynamic>>? refForContextOrSelection(
    FirebaseFirestore fs, {
    AdminContext? ctx, // <= nullable
    required ScopeKind scope,
    String? districtId,
  }) {
    if (ctx != null) {
      // old helper can still take non-null
      return refForContext(fs, ctx);
    }
    if (scope == ScopeKind.local) {
      return fs.collection('localMunicipalities');
    }
    if (scope == ScopeKind.district && (districtId ?? '').isNotEmpty) {
      return fs
          .collection('districts')
          .doc(districtId!)
          .collection('municipalities');
    }
    return null;
  }

  static String _displayName(String id, Map<String, dynamic>? data) {
    final n = (data?['name'] as String?)?.trim();
    return (n != null && n.isNotEmpty) ? n : id;
  }

  static List<String> _toUtilities(dynamic raw) {
    final list = (raw is List) ? raw.cast<dynamic>() : const [];
    final set = <String>{};
    for (final v in list) {
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'water' || s == 'electricity') set.add(s);
      }
    }
    return set.toList()..sort();
  }

  /// Create/Edit sheet
  static Future<void> openMunicipalitySheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> ref, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final idCtrl = TextEditingController(text: docId ?? '');
    final nameCtrl =
        TextEditingController(text: (existing?['name'] as String?) ?? '');

    // utilities state
    bool hasWater = _toUtilities(existing?['utilityType']).contains('water');
    bool hasElectricity =
        _toUtilities(existing?['utilityType']).contains('electricity');

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                Future<void> _save() async {
                  final id = idCtrl.text.trim();
                  final name = nameCtrl.text.trim();

                  if ((docId ?? id).isEmpty) return;
                  final utilities = <String>[
                    if (hasWater) 'water',
                    if (hasElectricity) 'electricity',
                  ];

                  final payload = <String, dynamic>{
                    if (name.isNotEmpty) 'name': name,
                    'utilityType': utilities,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (docId == null) {
                    // Creating (caller chooses the doc id)
                    await ref.doc(id).set({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  } else {
                    // Editing (cannot change doc id)
                    await ref.doc(docId).set(payload, SetOptions(merge: true));
                  }

                  // ignore: use_build_context_synchronously
                  Navigator.of(ctx).pop();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        docId == null
                            ? 'Create Municipality'
                            : 'Edit Municipality',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Doc ID (only on create)
                    if (docId == null) ...[
                      TextField(
                        controller: idCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Municipality ID *',
                            helperText: 'Used as the document ID',
                            labelStyle: TextStyle(color: Colors.black)),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text('ID: $docId',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                    ],

                    // Display name (optional)
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Display Name (optional)',
                          labelStyle: TextStyle(color: Colors.black)),
                    ),

                    const SizedBox(height: 16),
                    const Text('Utility Type',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.black)),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      checkColor: Colors.black,
                      activeColor: Colors.grey,
                      value: hasWater,
                      onChanged: (v) => setState(() => hasWater = v ?? false),
                      title: const Text(
                        'Water',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: hasElectricity,
                      checkColor: Colors.black,
                      activeColor: Colors.grey,
                      onChanged: (v) =>
                          setState(() => hasElectricity = v ?? false),
                      title: const Text(
                        'Electricity',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.save,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Save',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: _save,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmCascadeDelete(
      BuildContext context, String nameOrId) async {
    bool cascade = true;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text(
            'Delete Municipality',
            style: TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete "$nameOrId"?',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: cascade,
                checkColor: Colors.black,
                activeColor: Colors.black,
                onChanged: (v) => setState(() => cascade = v ?? true),
                title: const Text(
                  'Also delete users, departments and other data (recursive)',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                )),
            TextButton(
                onPressed: () => Navigator.pop(ctx, cascade),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.black),
                )),
          ],
        );
      }),
    );
  }

  Future<void> testDirectCall(String basePath) async {
    final projectId = Firebase.app().options.projectId;
    final uri = Uri.parse(
      'https://europe-west1-$projectId.cloudfunctions.net/deleteMunicipalityRecursive',
    );

    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken', // required for onCall
      },
      body: jsonEncode({
        'data': {'basePath': basePath}, // callable format
      }),
    );

    debugPrint('HTTP ${res.statusCode} ${res.body}');
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final col = refForContextOrSelection(
      FirebaseFirestore.instance,
      ctx: contextData, // may be null
      scope: scope,
      districtId: districtId,
    );

    if (col == null) {
      return const Center(
          child: Text(
        'Select a district/local context first.',
        style: TextStyle(color: Colors.black),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          // Sort client-side by display name
          final docs = [...(snap.data?.docs ?? const [])]..sort((a, b) {
              final an = _displayName(a.id, a.data());
              final bn = _displayName(b.id, b.data());
              return an.toLowerCase().compareTo(bn.toLowerCase());
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No municipalities found.',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.business_rounded),
                    label: const Text(
                      'Create first municipality',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () => openMunicipalitySheet(context, col),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final name = _displayName(d.id, data);
              final utilities = _toUtilities(data['utilityType']);
              final chips = utilities.isEmpty ? ['—'] : utilities;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${d.id}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children:
                            chips.map((u) => Chip(label: Text(u))).toList(),
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openMunicipalitySheet(context, col,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final name = _displayName(d.id, data);

                          // Grab handles BEFORE any await (so they don't rely on a possibly deactivated context)
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);

                          final cascade =
                              await _confirmCascadeDelete(context, name);
                          if (cascade == null) return;

                          if (cascade) {
                            final basePath = contextData!.isLocalMunicipality
                                ? 'localMunicipalities/${d.id}'
                                : 'districts/${contextData?.districtId}/municipalities/${d.id}';

                            try {
                              await testDirectCall(basePath);
                              final functions = FirebaseFunctions.instanceFor(
                                  region: 'europe-west1');
                              await functions
                                  .httpsCallable('deleteMunicipalityRecursive')
                                  .call({'basePath': basePath});

                              // If you might call Navigator here, guard with context.mounted
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Deleted "$name" and all nested data.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to delete recursively: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            // Simple doc delete (non-recursive)
                            await col.doc(d.id).delete();
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Deleted "$name". Nested data not removed.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//===================Notifications Tab=======================
class NotificationsTab extends StatelessWidget {
  final AdminContext contextData;
  const NotificationsTab({super.key, required this.contextData});

  static const _levelOptions = <String>['general', 'warning', 'severe'];

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _fmtNow() {
    final now = DateTime.now();
    // Example: 2025-08-14 – 08:37  (note the en dash U+2013)
    return '${now.year}-${_two(now.month)}-${_two(now.day)} – '
        '${_two(now.hour)}:${_two(now.minute)}';
  }

  // Create / Edit bottom sheet
  static Future<void> openNotificationSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> notifsRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final titleCtrl =
        TextEditingController(text: (existing?['title'] as String?) ?? '');
    final bodyCtrl =
        TextEditingController(text: (existing?['body'] as String?) ?? '');
    final userCtrl =
        TextEditingController(text: (existing?['user'] as String?) ?? '');
    final tokenCtrl =
        TextEditingController(text: (existing?['token'] as String?) ?? '');
    final dateCtrl = TextEditingController(
        text: (existing?['date'] as String?) ?? _fmtNow());

    String level = ((existing?['level'] as String?) ?? 'general').toLowerCase();
    if (!_levelOptions.contains(level)) level = 'general';
    bool read = (existing?['read'] as bool?) ?? false;

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      docId == null
                          ? 'Create Notification'
                          : 'Edit Notification',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Title *',
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Body *',
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.black,
                    focusColor: Colors.black,
                    value: level,
                    items: _levelOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => level = v ?? 'general'),
                    decoration: const InputDecoration(labelText: 'Level'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Read',
                      style: TextStyle(color: Colors.black),
                    ),
                    value: read,
                    onChanged: (v) => setState(() => read = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Date (string)',
                        helperText: 'Format: YYYY-MM-DD – HH:mm',
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                        labelText: 'User (optional)',
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tokenCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Token (optional)',
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      final title = titleCtrl.text.trim();
                      final body = bodyCtrl.text.trim();
                      final date = dateCtrl.text.trim();

                      if (title.isEmpty || body.isEmpty) {
                        messenger.showSnackBar(const SnackBar(
                          content: Text(
                            'Title and Body are required.',
                            style: TextStyle(color: Colors.black),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      final payload = <String, dynamic>{
                        'title': title,
                        'body': body,
                        'level': level,
                        'read': read,
                        'date': date, // string, as per your schema
                        'user': userCtrl.text.trim(),
                        'token': tokenCtrl.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (docId == null) {
                        await notifsRef.add({
                          ...payload,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await notifsRef
                            .doc(docId)
                            .set(payload, SetOptions(merge: true));
                      }

                      if (context.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final notifsRef = scoped.col(kColNotifications);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // date is a string "YYYY-MM-DD – HH:mm" -> lexicographically sortable
        stream: notifsRef.orderBy('date', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No notifications found.',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.add_alert,
                      color: Colors.green,
                    ),
                    label: const Text(
                      'Create notification',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () => openNotificationSheet(context, notifsRef),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final title = (data['title'] as String?) ?? '(untitled)';
              final body = (data['body'] as String?) ?? '';
              final level = (data['level'] as String?) ?? 'general';
              final date = (data['date'] as String?) ?? '';
              final read = (data['read'] as bool?) ?? false;
              final user = (data['user'] as String?) ?? '';
              final token = (data['token'] as String?) ?? '';

              Color chipColor(String l) {
                switch (l.toLowerCase()) {
                  case 'severe':
                    return Colors.red.shade100;
                  case 'warning':
                    return Colors.orange.shade100;
                  default:
                    return Colors.blue.shade100;
                }
              }

              return Card(
                child: ListTile(
                  leading: Icon(
                    read ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: read ? Colors.green : Colors.blueGrey,
                  ),
                  title: Text(title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(body),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: -8,
                          children: [
                            Chip(
                                label: Text(level),
                                backgroundColor: chipColor(level)),
                            if (date.isNotEmpty) Chip(label: Text(date)),
                            if (user.isNotEmpty)
                              Chip(
                                  label: Text(
                                'user: $user',
                                style: const TextStyle(color: Colors.black),
                              )),
                          ],
                        ),
                        if (token.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('token: $token',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: read ? 'Mark unread' : 'Mark read',
                        icon: Icon(
                            read
                                ? Icons.mark_email_unread
                                : Icons.mark_email_read,
                            color: read ? Colors.blueGrey : Colors.green),
                        onPressed: () async {
                          await notifsRef
                              .doc(d.id)
                              .set({'read': !read}, SetOptions(merge: true));
                        },
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openNotificationSheet(
                            context, notifsRef,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await _confirm(
                              context, 'Delete notification "$title"?');
                          if (ok) await notifsRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//==============Action Logs================
class ActionLogsTab extends StatefulWidget {
  final AdminContext contextData;
  const ActionLogsTab({super.key, required this.contextData});

  @override
  State<ActionLogsTab> createState() => _ActionLogsTabState();
}

class _ActionLogsTabState extends State<ActionLogsTab> {
  final _fs = FirebaseFirestore.instance;

  String? _selectedUploader; // +27...
  List<String> _addressOptions = []; // filled via callable
  String? _selectedAddress;
  bool _loadingAddresses = false;
  String? _error;

  CollectionReference<Map<String, dynamic>> get _actionLogsRoot =>
      _fs.doc(widget.contextData.basePath).collection(kColActionLogs);

  Future<void> _loadAddressesFor(String uploader) async {
    setState(() {
      _loadingAddresses = true;
      _error = null;
      _addressOptions = [];
      _selectedAddress = null;
    });
    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'europe-west1'); // your region
      final res = await functions.httpsCallable('listActionLogAddresses').call(
          {'basePath': widget.contextData.basePath, 'uploader': uploader});
      final List<dynamic> arr = (res.data as Map)['addresses'] ?? const [];
      final addrs = arr.map((e) => e.toString()).toList();
      if (!mounted) return;
      setState(() {
        _addressOptions = addrs;
        if (_addressOptions.isNotEmpty) {
          _selectedAddress = _addressOptions.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load addresses: $e');
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathPreview = '${widget.contextData.basePath}/$kColActionLogs';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & path
          const Row(
            children: [
              Icon(Icons.list_alt),
              SizedBox(width: 8),
              Expanded(
                child:
                    Text('Action Logs', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Path: $pathPreview',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),

          // --- Uploader dropdown (docs in actionLogs) ---
          const Text('Uploader',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 6),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _actionLogsRoot.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              final uploaderDocs = snap.data?.docs ?? const [];
              final ids = uploaderDocs.map((d) => d.id).toList()..sort();

              if (ids.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No uploader entries yet.'),
                        SizedBox(height: 4),
                        Text(
                            'Action logs will appear here when staff upload meter images or readings.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              // Ensure selected uploader is valid
              _selectedUploader ??= ids.first;
              if (!ids.contains(_selectedUploader)) {
                _selectedUploader = ids.first;
                // trigger loading addresses for the first uploader
                _loadAddressesFor(_selectedUploader!);
              }

              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedUploader,
                items: ids
                    .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedUploader = val);
                  _loadAddressesFor(val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              );
            },
          ),

          const SizedBox(height: 16),

          // --- Address dropdown (loaded via callable) ---
          const Text('Property Address',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 6),
          if (_loadingAddresses)
            const LinearProgressIndicator()
          else if (_addressOptions.isEmpty)
            const Text(
              'Pick an uploader to list addresses.',
              style: TextStyle(color: Colors.black),
            )
          else
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedAddress,
              items: _addressOptions
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAddress = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

          const SizedBox(height: 12),
          const Divider(),

          // --- Logs list (only when uploader + address chosen) ---
          Expanded(
            child: (_selectedUploader == null || _selectedAddress == null)
                ? const Center(
                    child: Text(
                    'Select uploader and address to view logs.',
                    style: TextStyle(color: Colors.black),
                  ))
                : _LogsList(
                    root: _actionLogsRoot,
                    uploader: _selectedUploader!,
                    address: _selectedAddress!,
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogsList extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> root;
  final String uploader;
  final String address;
  const _LogsList({
    required this.root,
    required this.uploader,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final col = root.doc(uploader).collection(address);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(
              child: Text(
            'No logs found for this address.',
            style: TextStyle(color: Colors.black),
          ));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final action = (data['actionType'] as String?) ?? '';
            final desc = (data['description'] as String?) ?? '';
            final ts = (data['timestamp']);
            final dt = (ts is Timestamp) ? ts.toDate() : null;

            final isImageUpload = action.toLowerCase().contains('image');
            final fileUrl = (data['fileUrl'] as String?) ?? '';

            // Reading details (may be water/electricity with different keys)
            final Map<String, dynamic> details =
                (data['details'] as Map?)?.cast<String, dynamic>() ?? const {};
            final accountNumber =
                details['accountNumber'] ?? data['accountNumber'];
            final meterNumber = details['water_meter_number'] ??
                details['meter_number'] ??
                data['meter_number'];
            final meterReading = details['water_meter_reading'] ??
                details['meter_reading'] ??
                data['meter_reading'];

            String tsLabel = dt == null
                ? ''
                : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Icon(isImageUpload ? Icons.image : Icons.fact_check),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            action.isEmpty ? 'Action' : action,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black),
                          ),
                        ),
                        if (tsLabel.isNotEmpty)
                          Text(tsLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        IconButton(
                          tooltip: 'Delete log',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await _confirm(
                                context, 'Delete this action log?');
                            if (ok) await col.doc(d.id).delete();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (desc.isNotEmpty) Text(desc),

                    // Coordinates if present
                    Builder(builder: (_) {
                      final lat = data['latitude'];
                      final lon = data['longitude'];
                      if (lat is num && lon is num) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              'coords: ${lat.toStringAsFixed(6)}, '
                              '${lon.toStringAsFixed(6)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Details if present (readings)
                    if (accountNumber != null ||
                        meterNumber != null ||
                        meterReading != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: -4,
                          children: [
                            if (accountNumber != null)
                              Chip(label: Text('Acct: $accountNumber')),
                            if (meterNumber != null)
                              Chip(label: Text('Meter: $meterNumber')),
                            if (meterReading != null)
                              Chip(label: Text('Reading: $meterReading')),
                          ],
                        ),
                      ),

                    // File URL helper
                    if (fileUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.link,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fileUrl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              child: const Text('Copy'),
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: fileUrl));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL copied'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//========================Calendar===================
class CalendarTab extends StatelessWidget {
  final AdminContext contextData;
  const CalendarTab({super.key, required this.contextData});

  // ——— helpers ———
  static const _wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static String _fmtPretty(DateTime d) {
    final dow = _wk[(d.weekday + 6) % 7]; // DateTime.weekday: Mon=1..Sun=7
    final mon = _mo[d.month - 1];
    return '$dow, $mon ${d.day}, ${d.year}';
  }

  static DateTime? _tryParsePretty(String s) {
    // Accept "Tue, Jan 28, 2025"
    final rx = RegExp(r'^[A-Za-z]{3},\s+([A-Za-z]{3})\s+(\d{1,2}),\s+(\d{4})$');
    final m = rx.firstMatch(s.trim());
    if (m == null) return null;
    final monName = m.group(1)!;
    final d = int.tryParse(m.group(2)!);
    final y = int.tryParse(m.group(3)!);
    final mIdx =
        _mo.indexWhere((e) => e.toLowerCase() == monName.toLowerCase());
    if (d == null || y == null || mIdx < 0) return null;
    return DateTime(y, mIdx + 1, d);
  }

  static Future<void> openEventSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> calRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final eventCtrl =
        TextEditingController(text: (existing?['eventDes'] as String?) ?? '');
    final dateCtrl = TextEditingController(
        text: (existing?['date'] as String?) ?? _fmtPretty(DateTime.now()));

    // initial date for picker
    DateTime init = _tryParsePretty(dateCtrl.text) ?? DateTime.now();

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      docId == null
                          ? 'Create Calendar Event'
                          : 'Edit Calendar Event',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: eventCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Event description *',
                        fillColor: Colors.black,
                        focusColor: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      labelStyle: const TextStyle(color: Colors.black),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: init,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            barrierColor: Colors.black,
                          );
                          if (picked != null) {
                            setState(() {
                              init = picked;
                              dateCtrl.text = _fmtPretty(picked);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.save,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Save',
                      selectionColor: Colors.grey,
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () async {
                      final desc = eventCtrl.text.trim();
                      final dateStr = dateCtrl.text.trim();
                      if (desc.isEmpty || dateStr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Date and description are required.'),
                              behavior: SnackBarBehavior.floating),
                        );
                        return;
                      }
                      final parsed = _tryParsePretty(dateStr) ?? init;
                      final payload = <String, dynamic>{
                        'eventDes': desc,
                        'date': dateStr, // keep the pretty string
                        'dateTs': Timestamp.fromDate(parsed), // for ordering
                        'updatedAt': FieldValue.serverTimestamp(),
                      };
                      if (docId == null) {
                        await calRef.add({
                          ...payload,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await calRef
                            .doc(docId)
                            .set(payload, SetOptions(merge: true));
                      }
                      if (context.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final calRef = scoped.col(kColCalendar);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: calRef
            .snapshots(), // no Firestore order; we’ll sort in memory via dateTs
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = [...(snap.data?.docs ?? const [])];

          // Sort by dateTs (Timestamp) if present; otherwise try parse "date"
          docs.sort((a, b) {
            final at = a.data()['dateTs'];
            final bt = b.data()['dateTs'];
            if (at is Timestamp && bt is Timestamp) {
              return at.compareTo(bt);
            }
            final as = (a.data()['date'] as String?) ?? '';
            final bs = (b.data()['date'] as String?) ?? '';
            final ad =
                _tryParsePretty(as) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd =
                _tryParsePretty(bs) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return ad.compareTo(bd);
          });

          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'No calendar events found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Path: ${calRef.path}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Create first event',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () => openEventSheet(context, calRef),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final dateStr = (data['date'] as String?) ?? '';
              final desc = (data['eventDes'] as String?) ?? '';
              final ts = data['dateTs'];
              String subtitle = desc;
              if (ts is Timestamp) {
                final dt = ts.toDate();
                subtitle = '$desc'
                    '\n(${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')})';
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    dateStr.isEmpty ? '(No date)' : dateStr,
                    selectionColor: Colors.grey,
                    style: const TextStyle(color: Colors.black),
                  ),
                  subtitle: Text(subtitle),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openEventSheet(context, calRef,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok =
                              await _confirm(context, 'Delete this event?');
                          if (ok) await calRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//================ Employees ======================================
class EmployeesTab extends StatelessWidget {
  final AdminContext contextData;
  const EmployeesTab({super.key, required this.contextData});

  static Future<void> openEmployeeSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> empRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final nameCtrl =
        TextEditingController(text: (existing?['name'] as String?) ?? '');
    final posCtrl =
        TextEditingController(text: (existing?['position'] as String?) ?? '');
    final emailCtrl =
        TextEditingController(text: (existing?['email'] as String?) ?? '');
    final numberCtrl =
        TextEditingController(text: (existing?['number'] as String?) ?? '');
    final altNumberCtrl = TextEditingController(
        text: (existing?['alternate_number'] as String?) ?? '');

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    docId == null ? 'Create Employee' : 'Edit Employee',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: posCtrl,
                  decoration: const InputDecoration(labelText: 'Position *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Primary number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: altNumberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Alternate number'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final pos = posCtrl.text.trim();
                    if (name.isEmpty || pos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and position are required.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final payload = <String, dynamic>{
                      'name': name,
                      'position': pos,
                      'email': emailCtrl.text.trim(),
                      'number': numberCtrl.text.trim(),
                      'alternate_number': altNumberCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      await empRef.add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await empRef
                          .doc(docId)
                          .set(payload, SetOptions(merge: true));
                    }
                    if (context.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final empRef = scoped.col(kColEmployees);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: empRef.orderBy('name').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No employees found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Path: ${empRef.path}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create first employee'),
                        onPressed: () => openEmployeeSheet(context, empRef),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final name = (data['name'] as String?) ?? '';
              final pos = (data['position'] as String?) ?? '';
              final email = (data['email'] as String?) ?? '';
              final number = (data['number'] as String?) ?? '';
              final alt = (data['alternate_number'] as String?) ?? '';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(name.isEmpty ? '(No name)' : name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pos.isNotEmpty) Text('Position: $pos'),
                      if (email.isNotEmpty) Text('Email: $email'),
                      if (number.isNotEmpty) Text('Number: $number'),
                      if (alt.isNotEmpty) Text('Alternate: $alt'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openEmployeeSheet(context, empRef,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok =
                              await _confirm(context, 'Delete this employee?');
                          if (ok) await empRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//======================= Fault Reporting ==========================
class FaultReportingTab extends StatelessWidget {
  final AdminContext contextData;
  const FaultReportingTab({super.key, required this.contextData});

  // ---------- date helpers ----------
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmtDatePretty(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)} – ${_two(dt.hour)}:${_two(dt.minute)}';

  static DateTime? _tryParseDate(String s) {
    final cleaned = s.trim().replaceAll('–', '-');
    final rx = RegExp(r'^(\d{4})-(\d{2})-(\d{2}).*?(\d{1,2}):(\d{2})$');
    final m = rx.firstMatch(cleaned);
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    final h = int.tryParse(m.group(4)!);
    final mi = int.tryParse(m.group(5)!);
    if (y == null || mo == null || d == null || h == null || mi == null)
      return null;
    return DateTime(y, mo, d, h, mi);
  }

  // ---------- bottom sheet (create / edit) ----------
  static Future<void> openFaultSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> faultsRef, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    // controllers
    final accountNumber = TextEditingController(
        text: (existing?['accountNumber'] as String?) ?? '');
    final address =
        TextEditingController(text: (existing?['address'] as String?) ?? '');
    final adminComment = TextEditingController(
        text: (existing?['adminComment'] as String?) ?? '');
    final attendeeAllocated = TextEditingController(
        text: (existing?['attendeeAllocated'] as String?) ?? '');
    final attendeeCom1 = TextEditingController(
        text: (existing?['attendeeCom1'] as String?) ?? '');
    final attendeeCom2 = TextEditingController(
        text: (existing?['attendeeCom2'] as String?) ?? '');
    final attendeeCom3 = TextEditingController(
        text: (existing?['attendeeCom3'] as String?) ?? '');
    final attendeeReturnCom = TextEditingController(
        text: (existing?['attendeeReturnCom'] as String?) ?? '');
    final depAllocated = TextEditingController(
        text: (existing?['depAllocated'] as String?) ?? '');
    final departmentSwitchComment = TextEditingController(
        text: (existing?['departmentSwitchComment'] as String?) ?? '');
    final faultDescription = TextEditingController(
        text: (existing?['faultDescription'] as String?) ?? '');
    final faultType =
        TextEditingController(text: (existing?['faultType'] as String?) ?? '');
    final managerAllocated = TextEditingController(
        text: (existing?['managerAllocated'] as String?) ?? '');
    final managerCom1 = TextEditingController(
        text: (existing?['managerCom1'] as String?) ?? '');
    final managerCom2 = TextEditingController(
        text: (existing?['managerCom2'] as String?) ?? '');
    final managerCom3 = TextEditingController(
        text: (existing?['managerCom3'] as String?) ?? '');
    final managerReturnCom = TextEditingController(
        text: (existing?['managerReturnCom'] as String?) ?? '');
    final reallocationComment = TextEditingController(
        text: (existing?['reallocationComment'] as String?) ?? '');
    final refCtrl =
        TextEditingController(text: (existing?['ref'] as String?) ?? '');
    final reporterContact = TextEditingController(
        text: (existing?['reporterContact'] as String?) ?? '');
    final uidCtrl =
        TextEditingController(text: (existing?['uid'] as String?) ?? '');
    final dateReportedCtrl = TextEditingController(
      text: (existing?['dateReported'] as String?) ??
          _fmtDatePretty(DateTime.now()),
    );

    bool faultResolved = (existing?['faultResolved'] as bool?) ?? false;
    int faultStage = (existing?['faultStage'] as num?)?.toInt() ?? 1;

    DateTime initDate = _tryParseDate(dateReportedCtrl.text) ?? DateTime.now();
    TimeOfDay initTime =
        TimeOfDay(hour: initDate.hour, minute: initDate.minute);

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                Future<void> pickDateTime() async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate == null) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: initTime,
                  );
                  final t = pickedTime ?? initTime;
                  initDate = DateTime(pickedDate.year, pickedDate.month,
                      pickedDate.day, t.hour, t.minute);
                  initTime = TimeOfDay(hour: t.hour, minute: t.minute);
                  setState(
                      () => dateReportedCtrl.text = _fmtDatePretty(initDate));
                }

                Future<void> save() async {
                  final dStr = dateReportedCtrl.text.trim();
                  final dt = _tryParseDate(dStr) ?? initDate;
                  final payload = <String, dynamic>{
                    'accountNumber': accountNumber.text.trim(),
                    'address': address.text.trim(),
                    'adminComment': adminComment.text.trim(),
                    'attendeeAllocated': attendeeAllocated.text.trim(),
                    'attendeeCom1': attendeeCom1.text.trim(),
                    'attendeeCom2': attendeeCom2.text.trim(),
                    'attendeeCom3': attendeeCom3.text.trim(),
                    'attendeeReturnCom': attendeeReturnCom.text.trim(),
                    'dateReported': dStr,
                    'depAllocated': depAllocated.text.trim(),
                    'departmentSwitchComment':
                        departmentSwitchComment.text.trim(),
                    'faultDescription': faultDescription.text.trim(),
                    'faultResolved': faultResolved,
                    'faultStage': faultStage,
                    'faultType': faultType.text.trim(),
                    'managerAllocated': managerAllocated.text.trim(),
                    'managerCom1': managerCom1.text.trim(),
                    'managerCom2': managerCom2.text.trim(),
                    'managerCom3': managerCom3.text.trim(),
                    'managerReturnCom': managerReturnCom.text.trim(),
                    'reallocationComment': reallocationComment.text.trim(),
                    'ref': refCtrl.text.trim(),
                    'reporterContact': reporterContact.text.trim(),
                    'uid': uidCtrl.text.trim(),
                    'dateTs': Timestamp.fromDate(dt),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (docId == null) {
                    await faultsRef.add({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await faultsRef
                        .doc(docId)
                        .set(payload, SetOptions(merge: true));
                  }
                  if (context.mounted) Navigator.of(ctx).pop();
                }

                InputDecoration _dec(String label) =>
                    InputDecoration(labelText: label);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        docId == null
                            ? 'Create Fault Report'
                            : 'Edit Fault Report',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                        controller: refCtrl,
                        decoration: _dec('Reference (e.g., [#6610d])')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: faultType,
                        decoration:
                            _dec('Fault Type (e.g., Water & Sanitation)')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: faultDescription,
                        decoration: _dec('Fault Description')),
                    const SizedBox(height: 8),
                    TextField(controller: address, decoration: _dec('Address')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: accountNumber,
                        decoration: _dec('Account Number')),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: faultStage,
                            items: const [1, 2, 3, 4, 5]
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text('Stage $v')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => faultStage = v ?? 1),
                            decoration: _dec('Fault Stage'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Resolved'),
                            value: faultResolved,
                            onChanged: (v) => setState(() => faultResolved = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: dateReportedCtrl,
                      readOnly: true,
                      decoration:
                          _dec('Date Reported (YYYY-MM-DD – HH:mm)').copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: pickDateTime,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // allocations/comments (manager/attendee/dep)
                    TextField(
                        controller: depAllocated,
                        decoration: _dec('Department Allocated')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: managerAllocated,
                        decoration: _dec('Manager Allocated')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: attendeeAllocated,
                        decoration: _dec('Attendee Allocated')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: managerCom1,
                        decoration: _dec('Manager Comment 1')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: managerCom2,
                        decoration: _dec('Manager Comment 2')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: managerCom3,
                        decoration: _dec('Manager Comment 3')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: managerReturnCom,
                        decoration: _dec('Manager Return Comment')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: attendeeCom1,
                        decoration: _dec('Attendee Comment 1')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: attendeeCom2,
                        decoration: _dec('Attendee Comment 2')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: attendeeCom3,
                        decoration: _dec('Attendee Comment 3')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: attendeeReturnCom,
                        decoration: _dec('Attendee Return Comment')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: reallocationComment,
                        decoration: _dec('Reallocation Comment')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: departmentSwitchComment,
                        decoration: _dec('Department Switch Comment')),
                    const SizedBox(height: 8),

                    TextField(
                        controller: reporterContact,
                        decoration: _dec('Reporter Contact (+27...)')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: uidCtrl, decoration: _dec('Reporter UID')),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: save,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final faultsRef = scoped.col(kColFaultReporting);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: faultsRef.snapshots(), // sort in memory by dateTs
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = [...(snap.data?.docs ?? const [])];

          // sort by dateTs (desc), fallback to dateReported parse
          docs.sort((a, b) {
            final at = a.data()['dateTs'];
            final bt = b.data()['dateTs'];
            if (at is Timestamp && bt is Timestamp) {
              return bt.compareTo(at);
            }
            final ad =
                _tryParseDate((a.data()['dateReported'] as String?) ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
            final bd =
                _tryParseDate((b.data()['dateReported'] as String?) ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'No fault reports found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Path: ${faultsRef.path}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create first fault'),
                        onPressed: () => openFaultSheet(context, faultsRef),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final refStr = (data['ref'] as String?) ?? '';
              final type = (data['faultType'] as String?) ?? '';
              final address = (data['address'] as String?) ?? '';
              final stage = (data['faultStage'] as num?)?.toInt() ?? 0;
              final resolved = (data['faultResolved'] as bool?) ?? false;
              final when = (data['dateReported'] as String?) ?? '';

              return Card(
                child: ListTile(
                  leading: Icon(
                    resolved ? Icons.check_circle : Icons.report,
                    color: resolved ? Colors.green : Colors.orange,
                  ),
                  title: Text(refStr.isEmpty ? '(No ref)' : refStr),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (type.isNotEmpty) Text('Type: $type'),
                      if (address.isNotEmpty) Text('Address: $address'),
                      Text(
                          'Stage: $stage   Resolved: ${resolved ? 'Yes' : 'No'}'),
                      if (when.isNotEmpty) Text('Reported: $when'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openFaultSheet(context, faultsRef,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await _confirm(
                              context, 'Delete this fault report?');
                          if (ok) await faultsRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//========================== Properties =====================

class PropertiesTab extends StatelessWidget {
  final AdminContext contextData;
  const PropertiesTab({super.key, required this.contextData});

  // ---------- bottom sheet (create / edit) ----------
  static Future<void> openPropertySheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> propsRef,
    AdminContext ctx, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    // controllers
    final accountCtrl = TextEditingController(
        text: (existing?['accountNumber'] as String?) ?? '');
    final eAccCtrl = TextEditingController(
        text: (existing?['electricityAccountNumber'] as String?) ?? '');
    final addressCtrl =
        TextEditingController(text: (existing?['address'] as String?) ?? '');
    final areaCodeCtrl = TextEditingController(
        text:
            (existing?['areaCode'] != null) ? '${existing?['areaCode']}' : '');
    final wardCtrl =
        TextEditingController(text: (existing?['ward'] as String?) ?? '');
    final firstCtrl =
        TextEditingController(text: (existing?['firstName'] as String?) ?? '');
    final lastCtrl =
        TextEditingController(text: (existing?['lastName'] as String?) ?? '');
    final idCtrl =
        TextEditingController(text: (existing?['idNumber'] as String?) ?? '');
    final tokenCtrl =
        TextEditingController(text: (existing?['token'] as String?) ?? '');
    final userIdCtrl =
        TextEditingController(text: (existing?['userID'] as String?) ?? '');

    // phone helpers
    String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');
    String _toLocalDigits(String raw) {
      var d = _digits(raw);
      if (d.startsWith('27')) d = d.substring(2);
      if (d.startsWith('0')) d = d.substring(1);
      return d;
    }

    final phoneCtrl = TextEditingController(
        text: _toLocalDigits((existing?['cellNumber'] as String?) ?? ''));

    final latCtrl = TextEditingController(
        text:
            (existing?['latitude'] != null) ? '${existing?['latitude']}' : '');
    final lngCtrl = TextEditingController(
        text: (existing?['longitude'] != null)
            ? '${existing?['longitude']}'
            : '');

    final wMeterCtrl = TextEditingController(
        text: (existing?['water_meter_number'] as String?) ?? '');
    final wReadCtrl = TextEditingController(
        text: (existing?['water_meter_reading'] as String?) ?? '');
    final eMeterCtrl = TextEditingController(
        text: (existing?['meter_number'] as String?) ?? '');
    final eReadCtrl = TextEditingController(
        text: (existing?['meter_reading'] as String?) ?? '');

    bool isAddressConfirmed =
        (existing?['isAddressConfirmed'] as bool?) ?? false;
    bool imgStateW = (existing?['imgStateW'] as bool?) ?? false;
    bool imgStateE = (existing?['imgStateE'] as bool?) ?? false;

    int _toInt(String s) => int.tryParse(s.trim()) ?? 0;
    double? _toDouble(String s) => double.tryParse(s.trim());

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctxSheet) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctxSheet).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                Future<void> _save() async {
                  // phone normalize to +27
                  var local = _digits(phoneCtrl.text);
                  if (local.startsWith('0')) local = local.substring(1);
                  if (local.length != 9) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Enter SA phone: 9 digits after +27')),
                    );
                    return;
                  }
                  final e164 = '+27$local';

                  final payload = <String, dynamic>{
                    // identity
                    'accountNumber': accountCtrl.text.trim(),
                    'electricityAccountNumber': eAccCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'areaCode': _toInt(areaCodeCtrl.text),
                    'ward': wardCtrl.text.trim(),
                    // people
                    'firstName': firstCtrl.text.trim(),
                    'lastName': lastCtrl.text.trim(),
                    'idNumber': idCtrl.text.trim(),
                    'userID': userIdCtrl.text.trim(),
                    'cellNumber': e164,
                    'token': tokenCtrl.text.trim(),
                    // coords
                    'latitude': _toDouble(latCtrl.text),
                    'longitude': _toDouble(lngCtrl.text),
                    // meters
                    'water_meter_number': wMeterCtrl.text.trim(),
                    'water_meter_reading': wReadCtrl.text.trim(),
                    'meter_number': eMeterCtrl.text.trim(),
                    'meter_reading': eReadCtrl.text.trim(),
                    // flags
                    'isAddressConfirmed': isAddressConfirmed,
                    'imgStateW': imgStateW,
                    'imgStateE': imgStateE,
                    // context
                    'isLocalMunicipality': ctx.isLocalMunicipality,
                    'districtId':
                        ctx.isLocalMunicipality ? null : ctx.districtId,
                    'municipalityId': ctx.municipalityId,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (docId == null) {
                    await propsRef.add({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await propsRef
                        .doc(docId)
                        .set(payload, SetOptions(merge: true));
                  }
                  if (context.mounted) Navigator.of(ctxSheet).pop();
                }

                InputDecoration _dec(String label) =>
                    InputDecoration(labelText: label);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        docId == null ? 'Create Property' : 'Edit Property',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address + ward
                    TextField(
                        controller: addressCtrl, decoration: _dec('Address')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: wardCtrl,
                        decoration: _dec('Ward (e.g. 07)'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: areaCodeCtrl,
                        decoration: _dec('Area Code'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      )),
                    ]),
                    const SizedBox(height: 8),

                    // Accounts
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: accountCtrl,
                        decoration: _dec('Water Account Number'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: eAccCtrl,
                        decoration: _dec('Electricity Account Number'),
                      )),
                    ]),
                    const SizedBox(height: 8),

                    // Names / ID
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: firstCtrl,
                              decoration: _dec('First Name'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: lastCtrl,
                              decoration: _dec('Last Name'))),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                        controller: idCtrl, decoration: _dec('ID Number')),
                    const SizedBox(height: 8),

                    // Phone/token
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Phone Number', prefixText: '+27 '),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: tokenCtrl,
                              decoration: _dec('FCM Token (optional)'))),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                        controller: userIdCtrl,
                        decoration: _dec('User UID (optional)')),
                    const SizedBox(height: 8),

                    // Coords
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: latCtrl,
                        decoration: _dec('Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: lngCtrl,
                        decoration: _dec('Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
                        ],
                      )),
                    ]),
                    const SizedBox(height: 8),

                    // Meters
                    const Text('Water Meter',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: wMeterCtrl,
                              decoration: _dec('Number'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: wReadCtrl,
                              decoration: _dec('Reading'))),
                    ]),
                    const SizedBox(height: 8),

                    const Text('Electricity Meter',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: eMeterCtrl,
                              decoration: _dec('Number'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: eReadCtrl,
                              decoration: _dec('Reading'))),
                    ]),
                    const SizedBox(height: 8),

                    // Flags
                    SwitchListTile(
                      value: isAddressConfirmed,
                      onChanged: (v) => setState(() => isAddressConfirmed = v),
                      title: const Text('Address Confirmed'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Row(children: [
                      Expanded(
                          child: SwitchListTile(
                        value: imgStateW,
                        onChanged: (v) => setState(() => imgStateW = v),
                        title: const Text('Water Image Uploaded'),
                        contentPadding: EdgeInsets.zero,
                      )),
                      Expanded(
                          child: SwitchListTile(
                        value: imgStateE,
                        onChanged: (v) => setState(() => imgStateE = v),
                        title: const Text('Electricity Image Uploaded'),
                        contentPadding: EdgeInsets.zero,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: _save,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final propsRef = scoped.col(kColProperties);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: propsRef.orderBy('address').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No properties found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Path: ${propsRef.path}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create first property',
                            style: TextStyle(color: Colors.black)),
                        onPressed: () =>
                            openPropertySheet(context, propsRef, contextData),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final address = (data['address'] as String?) ?? '';
              final accW = (data['accountNumber'] as String?) ?? '';
              final accE = (data['electricityAccountNumber'] as String?) ?? '';
              final ward = (data['ward'] as String?) ?? '';
              final confirmed = (data['isAddressConfirmed'] as bool?) ?? false;

              return Card(
                child: ListTile(
                  leading: Icon(confirmed ? Icons.home : Icons.home_outlined,
                      color: confirmed ? Colors.green : Colors.grey),
                  title: Text(address.isEmpty ? '(no address)' : address),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (accW.isNotEmpty) Text('Water Acct: $accW'),
                      if (accE.isNotEmpty) Text('Elec Acct: $accE'),
                      if (ward.isNotEmpty) Text('Ward: $ward'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => openPropertySheet(
                            context, propsRef, contextData,
                            docId: d.id, existing: data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok =
                              await _confirm(context, 'Delete this property?');
                          if (ok) await propsRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//========================= Suburbs =================================
class SuburbsTab extends StatelessWidget {
  final AdminContext contextData;
  const SuburbsTab({super.key, required this.contextData});

  static Future<void> _openSuburbSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> suburbsRef,
    AdminContext ctx, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final ctrl =
        TextEditingController(text: (existing?['suburb'] as String?) ?? '');

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (sheetCtx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    docId == null ? 'Create Suburb' : 'Edit Suburb',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Suburb *'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label:
                      const Text('Save', style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;

                    final payload = <String, dynamic>{'suburb': name};
                    if (docId == null) {
                      await suburbsRef.add(payload);
                    } else {
                      await suburbsRef
                          .doc(docId)
                          .set(payload, SetOptions(merge: true));
                    }
                    if (context.mounted) Navigator.of(sheetCtx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped =
        AdminScopedCollection(FirebaseFirestore.instance, contextData);
    final suburbsRef = scoped.col(kColSuburbs);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: suburbsRef.orderBy('suburb').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            // Empty collection state — allow creating the first doc
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No suburbs found for this municipality.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Path: ${suburbsRef.path}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create first suburb',
                            style: TextStyle(color: Colors.black)),
                        onPressed: () =>
                            _openSuburbSheet(context, suburbsRef, contextData),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i];
              final name =
                  (d.data()['suburb'] as String?)?.trim() ?? '(unnamed)';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(name),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => _openSuburbSheet(
                          context,
                          suburbsRef,
                          contextData,
                          docId: d.id,
                          existing: d.data(),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok =
                              await _confirm(context, 'Delete suburb "$name"?');
                          if (ok) await suburbsRef.doc(d.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =================== Small shared helpers ===================
Widget _w(double width, Widget child) => SizedBox(width: width, child: child);

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.red))),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.green),
            )),
      ],
    ),
  );
  return res ?? false;
}
