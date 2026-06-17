import 'pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'services/pedido_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pix_service.dart';
import 'pages/produtos_page.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/produtos_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Loja Distribuída",

      initialRoute: "/",

      routes: {
        "/": (context) => const SplashPage(),

        "/login": (context) => const LoginPage(),

        "/produtos": (context) => const ProdutosPage(),
      },
    );
  }
}

class WeatherService {
  final String apiKey = "0d423f3ab994d4c07877121e620bf396";

  // Buscar clima por cidade
  Future<Map<String, dynamic>> getWeatherByCity(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&lang=pt_br&appid=0d423f3ab994d4c07877121e620bf396",
    );

    final response = await http.get(url);
    Uri.parse("http://localhost:8000/produtos");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao buscar clima: ${response.body}");
    }
  }

  // Buscar clima por coordenadas
  Future<Map<String, dynamic>> getWeatherByLocation(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=pt_br&appid=0d423f3ab994d4c07877121e620bf396",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao buscar clima: ${response.body}");
    }
  }
}

Future<void> abrirWhatsApp() async {
  final Uri url = Uri.parse(
    "https://wa.me/5584991666404?text=Olá%20Gabriel,%20quero%20um%20site%20ou%20app",
  );

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw 'Não foi possível abrir o WhatsApp';
  }
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final weatherService = WeatherService();
  Map<String, dynamic>? data;
  String? erro;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    buscarClima();
  }

  Future<void> buscarClima() async {
    if (!mounted) return; // evita chamar setState se o widget já foi destruído

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Permissão de localização negada");
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final resultado = await weatherService.getWeatherByLocation(
        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return; // ✅ verificação antes de atualizar a UI
      setState(() {
        data = resultado;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return; // ✅ mesma verificação
      setState(() {
        erro = e.toString();
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) return const CircularProgressIndicator();

    if (erro != null) return Text('Erro: $erro');

    return Column(
      children: [
        Text(
          "${data!['main']['temp']}°C",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          data!['weather'][0]['description'],
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "Cidade: ${data!['name']}",
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

/* ================= MODELOS ================= */
class Produto {
  final String nome;
  final double preco;
  final String imagem;

  Produto({required this.nome, required this.preco, required this.imagem});
}

class Avaliacao {
  final String usuario;
  final int estrelas;
  final String comentario;

  Avaliacao({
    required this.usuario,
    required this.estrelas,
    required this.comentario,
  });
}

class DonoLoja {
  final String nome;
  final String estado;
  final String telefone;
  final String email;
  final String descricao;
  final int idade;

  DonoLoja({
    required this.nome,
    required this.estado,
    required this.telefone,
    required this.email,
    required this.descricao,
    required this.idade,
  });
}

// Calcula CRC16-CCITT (padrão PIX)
String calcularCRC16(String payload) {
  int crc = 0xFFFF;

  for (int i = 0; i < payload.length; i++) {
    crc ^= (payload.codeUnitAt(i) << 8);

    for (int j = 0; j < 8; j++) {
      if ((crc & 0x8000) != 0) {
        crc = (crc << 1) ^ 0x1021;
      } else {
        crc <<= 1;
      }
      crc &= 0xFFFF;
    }
  }

  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

// Gera PIX dinâmico com valor e ID do pedido
String gerarPixDinamico({
  required String chavePix,
  required String nome,
  required String cidade,
  required double valor,
  required String idPedido,
}) {
  String valorFormatado = valor.toStringAsFixed(2);

  String payloadSemCRC =
      "000201"
      "26580014BR.GOV.BCB.PIX"
      "01${chavePix.length.toString().padLeft(2, '0')}$chavePix"
      "52040000"
      "5303986"
      "54${valorFormatado.length.toString().padLeft(2, '0')}$valorFormatado"
      "5802BR"
      "59${nome.length.toString().padLeft(2, '0')}$nome"
      "60${cidade.length.toString().padLeft(2, '0')}$cidade"
      "62${(idPedido.length + 2).toString().padLeft(2, '0')}01$idPedido"
      "6304";

  String crc = calcularCRC16(payloadSemCRC);

  return payloadSemCRC + crc;
}

/* ================= DADOS ================= */
final List<Produto> produtos = [
  Produto(
    nome: 'Vestido Longo',
    preco: 25,
    imagem: 'assets/img/vestidolongo.jpg',
  ),
  Produto(
    nome: 'Vestido Rosa',
    preco: 20,
    imagem: 'assets/img/vestidorosa.jpg',
  ),
  Produto(
    nome: 'Vestido Verde',
    preco: 20,
    imagem: 'assets/img/vestidoverde.jpg',
  ),
  Produto(
    nome: 'Vestido Verde Escuro',
    preco: 20,
    imagem: 'assets/img/vestidoverdeescuro.jpg',
  ),
  Produto(
    nome: 'Vestido Azul Longo',
    preco: 20,
    imagem: 'assets/img/vestidoazullongo.jpg',
  ),
  Produto(
    nome: 'Vestido Branco Longo',
    preco: 20,
    imagem: 'assets/img/vestidobrancolongo.jpg',
  ),
  Produto(
    nome: 'Vestido Preto Curto',
    preco: 20,
    imagem: 'assets/img/vestidopretocurto.jpg',
  ),
  Produto(
    nome: 'Vestido Rosa',
    preco: 20,
    imagem: 'assets/img/vestidorosa1.jpg',
  ),
  Produto(
    nome: 'Vestido Vermelho',
    preco: 20,
    imagem: 'assets/img/vestidovermelho.jpg',
  ),
  Produto(
    nome: 'Vestido Laranja',
    preco: 20,
    imagem: 'assets/img/vestidolaranja.jpg',
  ),
  Produto(
    nome: 'Vestido Amarelo',
    preco: 20,
    imagem: 'assets/img/vestidoamarelo.jpg',
  ),
  Produto(
    nome: 'Vestido Azul e branco',
    preco: 20,
    imagem: 'assets/img/vestidoazulebranco.jpg',
  ),
  Produto(
    nome: 'Vestido Flor',
    preco: 20,
    imagem: 'assets/img/vestidoflor.jpg',
  ),
  Produto(nome: 'Macacão Floral', preco: 20, imagem: 'assets/img/macacao.jpg'),
  Produto(
    nome: 'Roupas de bazar',
    preco: 20,
    imagem: 'assets/img/bazaar-2835796_1920.jpg',
  ),
  Produto(
    nome: 'Corte Masculino',
    preco: 20,
    imagem: 'assets/img/homem-de-vista-lateral-cortando-o-cabelo.jpg',
  ),
  Produto(
    nome: 'Corte Feminino',
    preco: 30,
    imagem: 'assets/img/mulher-fazendo-tratamento-em-cabeleireiro.jpg',
  ),
  Produto(
    nome: 'Sobrancelha',
    preco: 25,
    imagem: 'assets/img/spa-4481538_1280.jpg',
  ),
  Produto(
    nome: 'Hidratação com Escova',
    preco: 30,
    imagem: 'assets/img/haircut-834280_1280.jpg',
  ),
  Produto(
    nome: 'Mão e pé',
    preco: 30,
    imagem: 'assets/img/people-2587157_1280.jpg',
  ),
];

List<Produto> carrinho = [];
Set<Produto> favoritos = {};
Map<Produto, int> quantidade = {};
Map<Produto, List<Avaliacao>> avaliacoes = {};

final dono = DonoLoja(
  nome: 'Gabriel Freire Bacelar',
  estado: 'Rio Grande do Norte',
  telefone: '+55 84 99166-6404',
  email: 'gabrielbacelar1000@gmail.com',
  descricao:
      'Sou desenvolvedor web, mobile e design 3D. Desenvolvi esta loja de bazar virtual para venda de roupas e salão de beleza. Eu vendo sites, aplicativos móveis e design 3d para e-commerce faço um preço ótimo! Entre em contato comigo: 84 99166-6404 chame no zap ou ligue para mim para saber sobre nossos serviços de tecnologia como sites e aplicativos!',
  idade: 22,
);

/* ================= APP PRINCIPAL ================= */
class AppPrincipal extends StatefulWidget {
  const AppPrincipal({super.key});

  @override
  State<AppPrincipal> createState() => _AppPrincipalState();
}

class _AppPrincipalState extends State<AppPrincipal> {
  int index = 0;

  final titulos = ['Home', 'Loja 🛍️', 'Carrinho 🛒'];

  @override
  Widget build(BuildContext context) {
    final telas = [
      const HomePage(),
      LojaPage(
        onAddCarrinho: (p) {
          setState(() {
            if (!carrinho.contains(p)) {
              carrinho.add(p);
            }
            quantidade[p] = (quantidade[p] ?? 0) + 1;
          });
        },
        onToggleFavorito: (p) {
          setState(() {
            favoritos.contains(p) ? favoritos.remove(p) : favoritos.add(p);
          });
        },
      ),
      CarrinhoPage(onUpdate: () => setState(() {})),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titulos[index])),
      body: telas[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Loja'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrinho',
          ),
        ],
      ),
    );
  }
}

/* ================= HOME ================= */
class CarouselHome extends StatefulWidget {
  const CarouselHome({super.key});

  @override
  State<CarouselHome> createState() => _CarouselHomeState();
}

class _CarouselHomeState extends State<CarouselHome> {
  final PageController controller = PageController();
  int indexAtual = 0;

  final List<String> imagens = [
    'https://picsum.photos/800/400?1',
    'https://picsum.photos/800/400?2',
    'https://picsum.photos/800/400?3',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller,
            itemCount: imagens.length,
            onPageChanged: (i) {
              setState(() => indexAtual = i);
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imagens[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imagens.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: indexAtual == i ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: indexAtual == i ? Colors.purple : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final produtosDestaque = produtos.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carrossel
        const CarouselHome(),

        const SizedBox(height: 20),

        // Clima
        const Center(child: WeatherWidget()),

        const SizedBox(height: 20),

        // Relógio
        const ClockDateWidget(),

        const SizedBox(height: 20),

        const Text(
          "Produtos em Destaque",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        const Text(
          "Mais vendidos",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: produtosDestaque.length,
            itemBuilder: (context, i) {
              final p = produtosDestaque[i];

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 10),
                child: Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Expanded(child: Image.asset(p.imagem, fit: BoxFit.cover)),

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              p.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text("R\$ ${p.preco.toStringAsFixed(2)}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Categorias",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            CategoriaItem(icon: Icons.checkroom, nome: "Roupas"),

            CategoriaItem(icon: Icons.spa, nome: "Beleza"),

            CategoriaItem(icon: Icons.face, nome: "Salão"),
          ],
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Promoção da Semana 🔥\nVestidos por R\$20",
            style: TextStyle(fontSize: 18),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          'Bem-vindo à Loja de Bazar e Salão de Beleza!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilDonoPage()),
            );
          },
          child: const Text('Sobre o Desenvolvedor'),
        ),

        ElevatedButton.icon(
          onPressed: abrirWhatsApp,
          icon: const Icon(Icons.chat),
          label: const Text("Falar no WhatsApp"),
        ),
      ],
    );
  }
}

class CategoriaItem extends StatelessWidget {
  final IconData icon;
  final String nome;

  const CategoriaItem({super.key, required this.icon, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.purple,
          child: Icon(icon, color: Colors.white),
        ),

        const SizedBox(height: 6),

        Text(nome),
      ],
    );
  }
}

final String apiKey = "0d423f3ab994d4c07877121e620bf396";

/* ================= RELÓGIO ================= */
class ClockDateWidget extends StatefulWidget {
  const ClockDateWidget({super.key});

  @override
  State<ClockDateWidget> createState() => _ClockDateWidgetState();
}

class _ClockDateWidgetState extends State<ClockDateWidget> {
  late Timer timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${now.day}/${now.month}/${now.year}',
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          '${now.hour}:${now.minute}:${now.second}',
          style: const TextStyle(fontSize: 28),
        ),
      ],
    );
  }
}

/* ================= LOJA ================= */
class LojaPage extends StatefulWidget {
  final Function(Produto) onAddCarrinho;
  final Function(Produto) onToggleFavorito;

  const LojaPage({
    super.key,
    required this.onAddCarrinho,
    required this.onToggleFavorito,
  });

  @override
  State<LojaPage> createState() => _LojaPageState();
}

class _LojaPageState extends State<LojaPage> {
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = produtos
        .where((p) => p.nome.toLowerCase().contains(busca.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar produtos...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => busca = v),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: listaFiltrada.length,
            itemBuilder: (_, i) {
              final p = listaFiltrada[i];

              return Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Image.asset(
                            p.imagem,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(
                                favoritos.contains(p)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => widget.onToggleFavorito(p),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            p.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('R\$ ${p.preco.toStringAsFixed(2)}'),
                          ElevatedButton(
                            onPressed: () {
                              widget.onAddCarrinho(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Adicionado ao carrinho'),
                                ),
                              );
                            },
                            child: const Text('Adicionar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ================= CARRINHO ================= */
/* ================= CARRINHO ================= */
class CarrinhoPage extends StatefulWidget {
  final VoidCallback onUpdate;
  const CarrinhoPage({super.key, required this.onUpdate});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  @override
  Widget build(BuildContext context) {
    if (carrinho.isEmpty) {
      return const Center(child: Text('Carrinho vazio'));
    }

    double total = carrinho.fold(
      0,
      (s, p) => s + (p.preco * (quantidade[p] ?? 1)),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: carrinho.length,
            itemBuilder: (_, i) {
              final p = carrinho[i];
              quantidade[p] ??= 1;

              return ListTile(
                leading: Image.asset(p.imagem, width: 50, fit: BoxFit.cover),
                title: Text(p.nome),
                subtitle: Text(
                  'Quantidade: ${quantidade[p]!} • R\$ ${(p.preco * quantidade[p]!).toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (quantidade[p]! > 1) {
                            quantidade[p] = quantidade[p]! - 1;
                          } else {
                            carrinho.remove(p);
                            quantidade.remove(p);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          quantidade[p] = quantidade[p]! + 1;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Total: R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPixPage()),
                  );
                },
                child: const Text('Pagar com PIX'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ================= CHECKOUT ================= */
class CheckoutPixPage extends StatefulWidget {
  const CheckoutPixPage({super.key});

  @override
  State<CheckoutPixPage> createState() => _CheckoutPixPageState();
}

final pixService = PixService();

class _CheckoutPixPageState extends State<CheckoutPixPage> {
  bool carregando = false;

  String? qrPix;
  String? idPagamento;

  Timer? timer;

  @override
  Widget build(BuildContext context) {
    double total = carrinho.fold(
      0,
      (s, p) => s + (p.preco * (quantidade[p] ?? 1)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento PIX')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// QR CODE
            qrPix == null
                ? const Text("Clique em gerar PIX")
                : QrImageView(
                    data: qrPix!,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),

            const SizedBox(height: 20),

            Text(
              'Total: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 20),

            const SelectableText('Chave PIX: 84992160269'),

            const Spacer(),

            /// BOTÃO GERAR PIX
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  carregando = true;
                });

                try {
                  final pix = await pixService.criarPix(total);

                  setState(() {
                    qrPix = pix["qr"];
                    idPagamento = pix["id"];
                    carregando = false;
                  });

                  verificarPagamento();
                } catch (e) {
                  setState(() {
                    carregando = false;
                  });
                }
              },
              child: const Text("Gerar PIX"),
            ),

            const SizedBox(height: 10),

            /// FINALIZAR PEDIDO
            carregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final pedidoService = PedidoService();

                      List<String> produtosPedido = carrinho
                          .map((p) => p.nome)
                          .toList();

                      await pedidoService.salvarPedido(total, produtosPedido);

                      carrinho.clear();
                      quantidade.clear();

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pedido finalizado com sucesso"),
                        ),
                      );
                    },
                    child: const Text("Finalizar Pedido"),
                  ),
          ],
        ),
      ),
    );
  }

  /// VERIFICA PAGAMENTO AUTOMÁTICO
  void verificarPagamento() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (idPagamento == null) return;

      final status = await pixService.verificarPagamento(idPagamento!);

      if (status["status"] == "approved") {
        timer.cancel();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Pagamento confirmado")));
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

/* ================= PERFIL ================= */
class PerfilDonoPage extends StatelessWidget {
  const PerfilDonoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o Desenvolvedor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${dono.nome}'),
            Text('Idade: ${dono.idade}'),
            Text('Estado: ${dono.estado}'),
            Text('Telefone: ${dono.telefone}'),
            Text('Email: ${dono.email}'),
            const SizedBox(height: 16),
            Text(dono.descricao),
          ],
        ),
      ),
    );
  }
}
