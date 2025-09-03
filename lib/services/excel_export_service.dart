import 'dart:io';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/summary_screen.dart';

class ExcelExportService {
  static Future<String?> exportToExcel({
    required String projectTitle,
    required String referent,
    required String travaux,
    required String adresse,
    required String acces,
    required List<MainTitle> mainTitles,
    required Map<String, double> adjustments,
  }) async {
    try {
      // Demander les permissions (seulement sur mobile)
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return null;
          }
        }
      }

      // Demander les permissions pour iOS
      if (!kIsWeb && Platform.isIOS) {
        // Sur iOS, on n'a pas besoin de permission photos pour sauvegarder des fichiers
        // Le dossier Documents est accessible sans permission spéciale
        print('iOS détecté - pas besoin de permission photos pour l\'export Excel');
      }

      // Charger le template existant
      final ByteData templateData = await rootBundle.load('assets/template.xlsx');
      final Uint8List templateBytes = templateData.buffer.asUint8List();
      var excel = Excel.decodeBytes(templateBytes);
      
      // Vérifier que le template a été chargé correctement
      if (excel.tables.isEmpty) {
        return 'Erreur: Template Excel vide ou corrompu';
      }
      
      // ================================
      // PREMIÈRE FEUILLE - INFORMATIONS
      // ================================
      String firstSheetName = excel.tables.keys.first;
      Sheet? firstSheet = excel[firstSheetName];
      
      if (firstSheet != null) {
        // C16: RÉFÉRENT
        firstSheet.cell(CellIndex.indexByString('C16')).value = TextCellValue(referent);
        
        // C19: TRAVAUX  
        firstSheet.cell(CellIndex.indexByString('C19')).value = TextCellValue(travaux);
        
        // C23-F23: ADRESSE (fusionner sur plusieurs cellules)
        firstSheet.cell(CellIndex.indexByString('C23')).value = TextCellValue(adresse);
        
        // C27-F27: ACCÈS
        firstSheet.cell(CellIndex.indexByString('C27')).value = TextCellValue(acces);
      }
      
      // ================================
      // DEUXIÈME FEUILLE - GARDER LE NOM ORIGINAL
      // ================================
      String secondSheetName = excel.tables.keys.length > 1 ? excel.tables.keys.toList()[1] : 'Sheet2';
      
      // NE PAS RENOMMER pour garder le logo et les styles !
      Sheet? secondSheet = excel[secondSheetName];
      
      if (secondSheet != null) {
        // B8: RÉFÉRENT
        secondSheet.cell(CellIndex.indexByString('B8')).value = TextCellValue(referent);
        
        // B9: ADRESSE  
        secondSheet.cell(CellIndex.indexByString('B9')).value = TextCellValue(adresse);
        
        // B10: TITRE PROJET
        secondSheet.cell(CellIndex.indexByString('B10')).value = TextCellValue(projectTitle);
        
        // Remplir les tableaux
        _fillTables(secondSheet, mainTitles, adjustments);
      }

      // Sauvegarder le fichier
      String fileName = 'Fiche_Metrique_${projectTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        if (kIsWeb) {
          // Sur web, créer un blob et télécharger
          return _downloadFileOnWeb(fileBytes, fileName);
        } else {
          // Sur mobile
          Directory? directory;
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
          } else {
            // Sur iOS, utiliser le dossier Documents qui est accessible via Files
            directory = await getApplicationDocumentsDirectory();
          }
          
          String filePath = '${directory!.path}/$fileName';
          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          
          // Sur iOS, ouvrir le fichier dans l'app Files
          if (Platform.isIOS) {
            await _openFileInFiles(filePath, fileName);
            return 'Fichier Excel exporté avec succès !\nConsultez l\'app Files pour le retrouver.';
          }
          
          return filePath;
        }
      }
      
      return null;
    } catch (e) {
      print('Erreur détaillée lors de l\'export Excel: $e');
      print('Stack trace: ${StackTrace.current}');
      return 'Erreur: $e';
    }
  }

  // ================================
  // REMPLIR LES TABLEAUX
  // ================================
  static void _fillTables(Sheet sheet, List<MainTitle> mainTitles, Map<String, double> adjustments) {
    int currentRow = 12; // Commence à la ligne 12 (A12 pour premier titre)
    
    for (MainTitle mainTitle in mainTitles) {
      // ================================
      // A12: TITRE PRINCIPAL (EN GRAS)
      // ================================
      var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      titleCell.value = TextCellValue(mainTitle.name.toUpperCase());
      // Appliquer le style gras
      titleCell.cellStyle = CellStyle(bold: true);
      
      // G12: TOTAL TITRE
      double titleTotal = _calculateMainTitleTotal(mainTitle, adjustments);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = 
        DoubleCellValue(titleTotal);
      
      currentRow += 1; // Passer à la ligne suivante
      
      // ================================
      // TITRE DIRECT (sans sous-titre)
      // ================================
      if (mainTitle.directItems.isNotEmpty) {
        // Ajouter les en-têtes de colonnes avec fond gris
        _addTableHeaders(sheet, currentRow);
        currentRow += 1;
        
        currentRow = _fillDirectItems(sheet, currentRow, mainTitle.directItems, mainTitle.name, adjustments);
        currentRow += 1; // Espace après les items directs
      }
      
      // ================================
      // SOUS-TITRES
      // ================================
      for (SubTitle subTitle in mainTitle.subTitles) {
        // B13: SOUS TITRE (EN GRAS)
        var subTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        subTitleCell.value = TextCellValue(subTitle.name);
        // Appliquer le style gras
        subTitleCell.cellStyle = CellStyle(bold: true);
        currentRow += 1;
        
        // Ajouter les en-têtes de colonnes avec fond gris
        _addTableHeaders(sheet, currentRow);
        currentRow += 1;
        
        // Remplir les items du sous-titre
        currentRow = _fillSubTitleItems(sheet, currentRow, subTitle, mainTitle.name, adjustments);
        
        currentRow += 1; // Espace entre sous-titres
      }
      
      currentRow += 1; // Espace entre titres principaux
    }
  }
  
  // Remplir les items directs d'un titre
  static int _fillDirectItems(Sheet sheet, int startRow, List<TableItem> items, String titleName, Map<String, double> adjustments) {
    int currentRow = startRow;
    double subTotal = 0;
    
    for (TableItem item in items) {
      if (item.descriptif.isNotEmpty) {
        currentRow = _writeTableRow(sheet, currentRow, item);
        subTotal += item.total;
      }
    }
    
    // Total avec ajustement
    double adjustment = adjustments['main_$titleName'] ?? 0;
    double finalTotal = subTotal + adjustment;
    
    // Affichage du total avec déduction visible
    if (adjustment != 0) {
      // Afficher la déduction
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Sous-total: ${subTotal.toStringAsFixed(1)}');
      currentRow++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Déduction: ${adjustment.toStringAsFixed(1)}');
      currentRow++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Total final: ${finalTotal.toStringAsFixed(1)}');
    } else {
      // Total simple sans déduction
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Total: ${finalTotal.toStringAsFixed(1)}');
    }
    
    return currentRow + 1;
  }
  
  // Remplir les items d'un sous-titre
  static int _fillSubTitleItems(Sheet sheet, int startRow, SubTitle subTitle, String mainTitleName, Map<String, double> adjustments) {
    int currentRow = startRow;
    double subTotal = 0;
    
    for (TableItem item in subTitle.items) {
      if (item.descriptif.isNotEmpty) {
        currentRow = _writeTableRow(sheet, currentRow, item);
        subTotal += item.total;
      }
    }
    
    // Total avec ajustement
    double adjustment = adjustments['sub_${mainTitleName}_${subTitle.name}'] ?? 0;
    double finalTotal = subTotal + adjustment;
    
    // Affichage du total avec déduction visible
    if (adjustment != 0) {
      // Afficher la déduction
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Sous-total: ${subTotal.toStringAsFixed(1)}');
      currentRow++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Déduction: ${adjustment.toStringAsFixed(1)}');
      currentRow++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Total final: ${finalTotal.toStringAsFixed(1)}');
    } else {
      // Total simple sans déduction
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = 
        TextCellValue('Total: ${finalTotal.toStringAsFixed(1)}');
    }
    
    return currentRow + 1;
  }
  
  // Écrire une ligne de tableau selon l'unité
  static int _writeTableRow(Sheet sheet, int row, TableItem item) {
    // B: Descriptif
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
      TextCellValue(item.descriptif);
    
    // C: Quantité
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
      DoubleCellValue(item.quantite);
    
    // D: Unité
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = 
      TextCellValue(item.unite);
    
    // Colonnes selon l'unité
    if (item.unite == 'm2') {
      // E: Longueur, F: Largeur, H: Total (colonne 7)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(item.longueur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(item.largeur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.total);
    } else if (item.unite == 'm3') {
      // E: Longueur, F: Largeur, G: Hauteur, H: Total
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(item.longueur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(item.largeur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(item.hauteur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.total);
    } else if (item.unite == 'mètre linéaire') {
      // E: Longueur, H: Total
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(item.longueur);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.total);
    } else {
      // unité: H: Total seulement (colonne 7)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.total);
    }
    
    return row + 1;
  }
  
  // Ajouter les en-têtes de colonnes avec fond gris et gras
  static void _addTableHeaders(Sheet sheet, int row) {
    List<String> headers = ['Descriptif', 'Quantité', 'Unité', 'Longueur', 'Largeur', 'Hauteur', 'Total'];
    
    for (int i = 0; i < headers.length; i++) {
      var headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: row));
      headerCell.value = TextCellValue(headers[i]);
      // Appliquer style gras (fond gris à appliquer manuellement dans le template)
      headerCell.cellStyle = CellStyle(
        bold: true,
      );
    }
  }
  
  // Calculer le total d'un titre principal avec ajustements
  static double _calculateMainTitleTotal(MainTitle mainTitle, Map<String, double> adjustments) {
    double total = 0;
    
    // Total des items directs
    for (TableItem item in mainTitle.directItems) {
      total += item.total;
    }
    total += adjustments['main_${mainTitle.name}'] ?? 0;
    
    // Total des sous-titres
    for (SubTitle subTitle in mainTitle.subTitles) {
      for (TableItem item in subTitle.items) {
        total += item.total;
      }
      total += adjustments['sub_${mainTitle.name}_${subTitle.name}'] ?? 0;
    }
    
    return total;
  }
  
  // Ouvrir le fichier dans l'app Files sur iOS
  static Future<void> _openFileInFiles(String filePath, String fileName) async {
    try {
      // Sur iOS, on peut utiliser un URL scheme pour ouvrir dans Files
      final Uri url = Uri.file(filePath);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: essayer d'ouvrir avec l'app Files
        final Uri filesUrl = Uri.parse('shareddocuments://$filePath');
        if (await canLaunchUrl(filesUrl)) {
          await launchUrl(filesUrl);
        } else {
          print('Impossible d\'ouvrir le fichier dans Files - fichier sauvegardé dans: $filePath');
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du fichier: $e');
      print('Fichier sauvegardé dans: $filePath');
    }
  }
  
  // Télécharger le fichier sur le web
  static String _downloadFileOnWeb(List<int> fileBytes, String fileName) {
    try {
      // Créer un blob et télécharger
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'Fichier Excel téléchargé avec succès !';
    } catch (e) {
      return 'Erreur lors du téléchargement: $e';
    }
  }
} 