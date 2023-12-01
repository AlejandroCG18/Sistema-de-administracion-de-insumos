import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:shared_preferences/shared_preferences.dart';
import 'inicio.dart';

void main() {
  runApp(LoadScreen());
}

class LoadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? dbName;
  Database? _database;
  String? _selectedImagePath;
  String? _selectedDbName;
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carga de Archivo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF00563F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
            final username = usernameController.text;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(username: username)));
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.folder_open),
                onPressed: () async {
                  try {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['db'],
                    );

                    if (result != null) {
                      String dbPath = result.files.single.path!;
                      String dbName = basename(dbPath);

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString('lastSelectedFile', dbName);

                      setState(() {
                        _selectedImagePath = 'assets/bd.png.jpg';
                        dbName = dbName;
                        _selectedDbName = dbName;
                      });

                      _database = await openDatabase(dbPath);
                    }
                  } catch (e) {
                    print('Error: $e');
                  }
                },
              ),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.visibility),
                onPressed: () {
                  _showFilterScreen(context);
                },
              ),
              SizedBox(width: 20),
            ],
          ),
          SizedBox(height: 20),
          _selectedDbName != null
              ? Column(
                  children: [
                    Image.asset(
                      _selectedImagePath ?? '',
                      height: 55,
                      width: 55,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nombre del archivo: $_selectedDbName',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : SizedBox.shrink(),
          IconButton(
            icon: Icon(Icons.video_camera_back),
            alignment: Alignment.bottomRight,
            onPressed: () {},
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Generar y Editar PDF'),
          ),
        ],
      ),
    );
  }

  void _showFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          database: _database,
          selectedImagePath: _selectedImagePath,
          selectedDbName: _selectedDbName,
        ),
      ),
    );
  }
}

class DatabaseTableScreen extends StatefulWidget {
  final String dbName;
  final String tableName;
  final Database database;
  final String? selectedImagePath;
  final String? selectedDbName;
  String montoIngresado;

  var tableData;

  DatabaseTableScreen({
    required this.dbName,
    required this.tableName,
    required this.database,
    this.selectedImagePath,
    this.selectedDbName,
    required this.montoIngresado,
  });

  @override
  _DatabaseTableScreenState createState() => _DatabaseTableScreenState();
}

class _DatabaseTableScreenState extends State<DatabaseTableScreen> {
  late List<int> quantities;
  late double total = 0;

  get selectedItems => null;

  Map<String, dynamic>? get data => null;

  @override
  void initState() {
    super.initState();
    quantities = widget.tableData != null
        ? List.filled(widget.tableData!.length, 0)
        : [];
    total = 0;
  }

  void _addToRemission(int index, int count, Map<String, dynamic> rowData) {
    // Agregar los insumos a la remisión según la lógica necesaria
    for (int i = 0; i < count; i++) {
      selectedItems.add({
        'No. Partida': rowData['No. Partida'],
        'Partida': rowData['Partida'],
        'Descripcion': rowData['Descripcion'],
        'Precio Unitario': rowData['Precio Unitario'],
      });
    }
    DataCell(
      CounterWidget(
        onUpdateTotal: (count) {
          _updateTotal(index, count, data!, context as BuildContext);
        },
        onAddToRemission: (count) {
          _addToRemission(index, count, data!);
        },
      ),
    );

    // Llamar a la función para generar y guardar el PDF
    _generatePDF();
  }

  void _generatePDF() {
    final pdf = pdfWidgets.Document();

    // Agregar contenido al PDF
    pdf.addPage(
      pdfWidgets.MultiPage(
        build: (context) => [
          pdfWidgets.Header(
            level: 0,
            text: 'Remisión de Insumos',
          ),
          for (var item in selectedItems)
            pdfWidgets.Text(
              'No. Partida: ${item['No. Partida']}\n'
              'Partida: ${item['Partida']}\n'
              'Descripción: ${item['Descripcion']}\n'
              'Precio Unitario: ${item['Precio Unitario']}\n\n',
            ),
        ],
      ),
    );

    // Guardar el PDF en el almacenamiento local
    final output = File('remision.pdf').openWrite();
    pdf.save().then((value) => output.close());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF00563F),
        centerTitle: true,
        title: Text(
          'Tabla - ${widget.tableName}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTableData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay datos en la tabla ${widget.tableName}'));
          } else {
            List<Map<String, dynamic>> tableData = snapshot.data!;

            // Reemplaza esta sección de tu código en _DatabaseTableScreenState
            return ListView(
              scrollDirection: Axis.vertical,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Monto Disponible: \$ ${widget.montoIngresado}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      ...tableData[0]
                          .keys
                          .map((key) => DataColumn(label: Text(key)))
                          .toList(),
                      DataColumn(label: Text('Cantidad')),
                    ],
                    rows: tableData
                        .asMap()
                        .map((index, data) {
                          quantities
                              .add(0); // Inicializar la cantidad para cada fila
                          return MapEntry(
                            index,
                            DataRow(
                              cells: [
                                ...data.values
                                    .map((value) => DataCell(Text('$value')))
                                    .toList(),
                                DataCell(
                                  CounterWidget(
                                    onUpdateTotal: (count) {
                                      _updateTotal(index, count, data, context);
                                    },
                                    onAddToRemission: (int) {},
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .values
                        .toList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getTableData() async {
    try {
      return await widget.database
          .rawQuery('SELECT * FROM ${widget.tableName};');
    } catch (e) {
      print('Error al obtener los datos de la tabla: $e');
      return [];
    }
  }

  void _updateTotal(int index, int count, Map<String, dynamic> rowData,
      BuildContext context) {
    // Reemplaza 'Precio Unitario' con el nombre real de la columna de precio
    String precioUnitarioString = rowData['Precio Unitario'] ?? '0';
    String cleanedPrice =
        precioUnitarioString.replaceAll(RegExp(r'[^0-9.]'), '');
    double price = double.parse(cleanedPrice);

    // Validar que el índice no sea negativo y que quantities y widget.tableData no sean nulos
    if (index >= 0 && widget.tableData != null) {
      quantities[index] = count;
    }

    // Realizar la acción opuesta al incremento en el monto disponible
    double montoDisponible = double.parse(widget.montoIngresado);

    // Calcular el total actual para cada fila y restar al monto disponible
    double rowTotal = count * price;
    total = quantities.fold(0, (sum, quantity) => sum + quantity * price);

    // Verificar si el monto disponible es suficiente
    if (montoDisponible >= rowTotal) {
      montoDisponible -= rowTotal;

      // Redondear el monto disponible a dos decimales
      montoDisponible = double.parse(montoDisponible.toStringAsFixed(2));

      // Asegurarse de que el monto redondeado sea mayor a 5
      montoDisponible = montoDisponible > 5.0 ? montoDisponible : 5.0;
    } else {
      // Mostrar un Snackbar si el monto disponible no es suficiente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monto disponible insuficiente'),
        ),
      );
      return; // No realizar más acciones si el monto no es suficiente
    }

    // Actualizar el estado
    setState(() {
      // Actualizar la variable montoIngresado si es necesario
      widget.montoIngresado = montoDisponible.toString();
    });
  }
}

class CounterWidget extends StatefulWidget {
  final Function(int) onUpdateTotal;
  final Function(int) onAddToRemission; // Nueva función de callback

  CounterWidget({required this.onUpdateTotal, required this.onAddToRemission});

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            setState(() {
              if (count > 0) count--;
              widget.onUpdateTotal(count);
            });
          },
        ),
        Text('$count'),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            setState(() {
              count++;
              widget.onUpdateTotal(count);
              widget.onAddToRemission(
                  count); // Llama a la nueva función de callback
            });
          },
        ),
      ],
    );
  }
}

class FilterScreen extends StatefulWidget {
  final Database? database;
  final String? selectedImagePath;
  final String? selectedDbName;

  FilterScreen(
      {Key? key, this.database, this.selectedImagePath, this.selectedDbName})
      : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final TextEditingController _filterController = TextEditingController();
  List<String> _filteredTables = [];
  String _montoIngresado = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Filtrar por Nombre',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF00563F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _filterController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Tabla',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _applyFilter(context);
              },
              child: Text('Buscar'),
            ),
            SizedBox(height: 20),
            if (_filteredTables.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resultados del filtro:'),
                      SizedBox(height: 10),
                      for (String tableName in _filteredTables)
                        ListTile(
                          title: Text(tableName),
                          onTap: () {
                            _showAmountInputDialog(context, tableName);
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(BuildContext context) {
    String filter = _filterController.text;
    _filteredTables = _getFilteredTables(filter);
    setState(() {
      if (_filteredTables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontraron resultados'),
          ),
        );
      }
    });
  }

  List<String> _getFilteredTables(String filter) {
    return [
      'P1',
      'P2',
      'P3',
      'P4',
      'P5',
      'P6',
      'P7',
      'P8',
      'P9',
      'P10',
      'P11',
      'P12',
      'P13',
      'P14',
      'P15',
      'P16'
    ]
        .where((table) => table.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  void _showAmountInputDialog(BuildContext context, String tableName) async {
    final TextEditingController montoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ingrese el monto disponible para $tableName'),
          content: TextField(
            controller: montoController,
            onChanged: (value) {
              setState(() {
                _montoIngresado = value;
              });
            },
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el AlertDialog
                _navigateToTableScreen(
                    context, tableName, montoController.text);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );

    setState(() {
      _montoIngresado = montoController.text;
    });
  }

  void _navigateToTableScreen(
      BuildContext context, String tableName, String montoIngresado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatabaseTableScreen(
          dbName: widget.selectedDbName ?? '',
          tableName: tableName,
          database: widget.database!,
          selectedImagePath: widget.selectedImagePath,
          selectedDbName: widget.selectedDbName,
          montoIngresado: _montoIngresado,
        ),
      ),
    );
  }
}
