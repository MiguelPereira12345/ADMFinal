import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/session_scope.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/grid_menu.dart';
import 'widgets/notification_bell_button.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTerms();
    });
  }

  Future<void> _checkTerms() async {
    final session = SessionScope.of(context);
    final userId = session.userId;
    // Se não houver userId, talvez não estejamos logados corretamente, ignoramos
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Chave única por user e versão dos termos
    final key = 'accepted_terms_v1_$userId';
    final accepted = prefs.getBool(key) ?? false;

    if (!accepted && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          const primaryGold = Color(0xFFA87B05);
          final titleStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87);
          final bodyStyle = const TextStyle(fontSize: 13, height: 1.5, color: Colors.black54);
          
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Termos e Condições', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: SizedBox(
                width: double.maxFinite,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Identificação do responsável pelo tratamento', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('CLINIMOLELOS, LDA, sociedade comercial por quotas, com o NIPC nº508353424 e com sede na Rua Dr. Adriano Figueiredo, nº 158, Pedra da Vista, 3460 Tondela\nContato do EPD (Encarregado da Proteção de Dados) xxxxx@xxxxx', style: bodyStyle, textAlign: TextAlign.justify),
                        
                        const SizedBox(height: 16),
                        Text('2. Informação, consentimento e finalidade do tratamento', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('A Lei da Proteção de Dados Pessoais (em diante “LPD”) e o Regulamento Geral de Proteção de Dados (Regulamento (UE) 2016/679 do Parlamento Europeu e do Conselho de 27 de abril de 2016, em diante “RGPD”) e a Lei 58/2019, de 8 de agosto, asseguram a proteção das pessoas singulares no que diz respeito ao tratamento de dados pessoais e à livre circulação desses dados.\nMediante a aceitação da presente Política de Privacidade e/ou Termos e Condições o utilizador presta o seu consentimento informado, expresso, livre e inequívoco para que os dados pessoais fornecidos sejam incluídos num ficheiro da responsabilidade da CLINIMOLELOS, cujo tratamento nos termos do RGPD cumpre as medidas de segurança técnicas e organizativas adequadas.\nOs dados presentes nesta base são unicamente os dados prestados pelos próprios, progenitores em caso de menores, maiores acompanhados ou cuidadores informais, na altura do seu registo, sendo tratados apenas para a criação do histórico clínico do utente.\nEm caso algum será solicitada informação sobre convicções filosóficas ou políticas, filiação partidária ou sindical, fé religiosa, vida privada e origem racial. Os dados recolhidos não serão cedidos a outras pessoas ou outras entidades, sem o consentimento prévio do titular dos dados.', style: bodyStyle, textAlign: TextAlign.justify),
                        
                        const SizedBox(height: 16),
                        Text('3. Medidas de segurança', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('A CLINIMOLELOS, declara que implementou e continuará a implementar as medidas de segurança de natureza técnica e organizativa necessárias para garantir a segurança dos dados de carácter pessoal e clínico que lhe sejam fornecidos visando evitar a sua alteração, perda, tratamento e/ou acesso não autorizado, tendo em conta o estado atual da tecnologia, a natureza dos dados armazenados e os riscos a que estão expostos bem como garante a confidencialidade dos mesmos.', style: bodyStyle, textAlign: TextAlign.justify),

                        const SizedBox(height: 16),
                        Text('4. Exercício dos direitos', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('O titular dos dados pessoais ou os representantes legais podem exercer a todo o tempo, os seus direitos de acesso, retificação, apagamento, limitação, oposição e portabilidade.', style: bodyStyle, textAlign: TextAlign.justify),
                        
                        const SizedBox(height: 16),
                        Text('5. Prazo de conservação', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('A clínica apenas trata os dados pessaois durante o período que se revele necessário ao cumprimento da sua finalidade (criação de histórico de saúde do utente), sem prejuízo dos dados serem conservados por um período superior, por exigências legais.', style: bodyStyle, textAlign: TextAlign.justify),
                        
                        const SizedBox(height: 16),
                        Text('6. Autoridade de controlo', style: titleStyle),
                        const SizedBox(height: 4),
                        Text('Nos termos legais, o titular dos dados tem o direito de apresentar uma reclamação em matéria de proteção de dados pessoais à autoridade de controlo competente, a Comissão Nacional de Proteção de Dados (CNPD).', style: bodyStyle, textAlign: TextAlign.justify),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await prefs.setBool(key, true);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Li e Aceito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFFAF7F4);
    final cardBg = Colors.white;
    final primaryGold = const Color(0xFFA87B05);
    final session = SessionScope.of(context);
    final nome = session.user?.nome;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Image.asset('assets/CliniMolelos.png'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Clinimolelos',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const NotificationBellButton(),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // CARD PRINCIPAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${nome != null && nome.isNotEmpty ? nome : 'Paciente'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bem-vindo de volta ao seu espaço de paciente',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/asminhasconsultas',
                              );
                            },
                            child: const Text(
                              'Marcar Consulta',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // GRID MENU
                  const GridMenu(),



                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
