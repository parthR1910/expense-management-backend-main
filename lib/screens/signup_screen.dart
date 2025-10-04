import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/currency_service.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _country;
  bool _loading = false;
  List<CountryCurrency> _countries = const [];
  bool _loadingCountries = true;
  String? _countriesError;

  // Organizations dropdown state
  List<Map<String, String>> _orgs = const [];
  String? _orgId;
  bool _loadingOrgs = true;
  String? _orgsError;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadOrganizations();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
      _countriesError = null;
    });
    try {
      final list = await CurrencyService.fetchCountries();
      // Sort alphabetically by country name
      list.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _countries = list;
        _loadingCountries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countriesError = 'Failed to load countries';
        _loadingCountries = false;
      });
    }
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _loadingOrgs = true;
      _orgsError = null;
    });
    try {
      // Fetch from Firestore companies collection and use it for Organization dropdown
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('name')
          .get();
      var data = snap.docs
          .map(
            (d) => {
              'id': d.id,
              'name': (d.data()['name'] ?? 'Organization').toString(),
            },
          )
          .toList();

      // Fallback demo organizations if none exist yet
      if (data.isEmpty) {
        data = [
          {'id': 'local:acme', 'name': 'Acme Corp'},
          {'id': 'local:globex', 'name': 'Globex'},
          {'id': 'local:initech', 'name': 'Initech'},
          {'id': 'local:umbrella', 'name': 'Umbrella Co.'},
        ];
      }

      if (!mounted) return;
      setState(() {
        _orgs = data;
        // Auto-select first company for faster signup
        if (_orgId == null && _orgs.isNotEmpty) {
          _orgId = _orgs.first['id'];
        }
        _loadingOrgs = false;
      });
    } catch (_) {
      // On error, also provide fallback demo organizations
      if (!mounted) return;
      setState(() {
        _orgs = const [
          {'id': 'local:acme', 'name': 'Acme Corp'},
          {'id': 'local:globex', 'name': 'Globex'},
          {'id': 'local:initech', 'name': 'Initech'},
          {'id': 'local:umbrella', 'name': 'Umbrella Co.'},
        ];
        _orgsError = 'Showing sample organizations';
        _loadingOrgs = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_orgId == null || _orgId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organization')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Fetch selected company (organization) details
      final compSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(_orgId)
          .get();
      final comp = compSnap.data() ?? {};
      final companyName = (comp['name'] ?? '') as String;
      final companyCurrency = (comp['currency_code'] ?? '') as String;
      final companyCountry = (comp['country'] ?? '') as String;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'role': 'Employee',
            // Link user to selected company
            'company_id': _orgId,
            'company_name': companyName,
            'company_currency_code': companyCurrency,
            'company_country': companyCountry,
            // User's selected country from dropdown (if any)
            'country': _country,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Optional: also add a reference under the company document
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_orgId)
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'role': 'Employee',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signup successful!')));
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer.withOpacity(0.25), cs.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Signup',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your admin account to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 30,
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: cs.primary,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Name is required';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Enter a valid name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Organization Dropdown
                              if (_loadingOrgs)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else if (_orgsError != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('$_orgsError — tap to retry'),
                                    ),
                                    TextButton(
                                      onPressed: _loadOrganizations,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              else
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _orgId,
                                  items: _orgs
                                      .map(
                                        (o) => DropdownMenuItem(
                                          value: o['id'],
                                          child: Text(
                                            o['name'] ?? 'Organization',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _orgId = v),
                                  decoration: InputDecoration(
                                    labelText: 'Organization',
                                    prefixIcon: Icon(
                                      Icons.apartment,
                                      color: cs.primary,
                                    ),
                                  ),
                                  selectedItemBuilder: (context) => _orgs
                                      .map((o) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              o['name'] ?? 'Organization',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Select an organization'
                                      : null,
                                ),
                              const SizedBox(height: 14),

                              // Country Dropdown
                              if (_loadingCountries)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else if (_countriesError != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$_countriesError — tap to retry',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadCountries,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              else
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _country,
                                  items: _countries
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.code,
                                          child: Text(
                                            c.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _country = v),
                                  decoration: InputDecoration(
                                    labelText: 'Country',
                                    prefixIcon: Icon(
                                      Icons.public,
                                      color: cs.primary,
                                    ),
                                  ),
                                  selectedItemBuilder: (context) => _countries
                                      .map((c) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              c.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Select a country'
                                      : null,
                                ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _emailCtrl,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: cs.primary,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  final rx = RegExp(r'^\S+@\S+\.[\w\-]+$');
                                  if (!rx.hasMatch(v.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: cs.primary,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: cs.primary,
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passwordCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              FilledButton(
                                onPressed: _loading ? null : _signup,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Sign Up'),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                                child: const Text(
                                  'Already have an account? Login',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
