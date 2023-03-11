import 'package:brisk/constants/download_status.dart';
import 'package:brisk/constants/file_type.dart';
import 'package:brisk/dao/download_item_dao.dart';
import 'package:brisk/provider/download_request_provider.dart';
import 'package:brisk/provider/pluto_grid_util.dart';
import 'package:brisk/provider/queue_provider.dart';
import 'package:brisk/util/file_util.dart';
import 'package:brisk/widget/download/add_url_dialog.dart';
import 'package:brisk/widget/download/download_info_dialog.dart';
import 'package:brisk/widget/download/download_row_pop_up_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:io';

import '../../db/hive_boxes.dart';
import 'download_progress_window.dart';

class DownloadGrid extends StatefulWidget {
  @override
  State<DownloadGrid> createState() => _DownloadGridState();
}

class _DownloadGridState extends State<DownloadGrid> {
  late List<PlutoColumn> columns;

  @override
  void didChangeDependencies() {
    initColumns(context);
    super.didChangeDependencies();
  }

  void initColumns(BuildContext context) {
    columns = [
      PlutoColumn(
        readOnly: true,
        hide: true,
        width: 80,
        title: 'Id',
        field: 'id',
        type: PlutoColumnType.number(),
      ),
      PlutoColumn(
        enableRowChecked: true,
        width: 300,
        title: 'File Name',
        field: 'file_name',
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final fileName = rendererContext.row.cells["file_name"]!.value;
          final id = rendererContext.row.cells["id"]!.value;
          final status = rendererContext.row.cells["status"]!.value;
          final fileType = FileUtil.detectFileType(fileName);
          return Row(
            children: [
              DownloadRowPopUpMenuButton(status: status, id: id),
              SizedBox(
                width: fileType == DLFileType.program ? 25 : 30,
                height: fileType == DLFileType.program ? 25 : 30,
                child: SvgPicture.asset(
                  FileUtil.resolveFileTypeIconPath(fileType.name),
                  color: FileUtil.resolveFileTypeIconColor(fileType.name),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  rendererContext.row.cells[rendererContext.column.field]!.value
                      .toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        readOnly: true,
        width: 90,
        title: 'Size',
        field: 'size',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        readOnly: true,
        width: 100,
        title: 'Progress',
        field: 'progress',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
          readOnly: true,
          width: 140,
          title: "Status",
          field: "status",
          type: PlutoColumnType.text()),
      PlutoColumn(
        readOnly: true,
        enableSorting: false,
        width: 122,
        title: 'Transfer Rate',
        field: 'transfer_rate',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        readOnly: true,
        width: 100,
        title: 'Time Left',
        field: 'time_left',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        readOnly: true,
        width: 100,
        title: 'Start Date',
        field: 'start_date',
        type: PlutoColumnType.date(),
      ),
      PlutoColumn(
        readOnly: true,
        width: 120,
        title: 'Finish Date',
        field: 'finish_date',
        type: PlutoColumnType.date(),
      ),
      PlutoColumn(
        readOnly: true,
        hide: true,
        width: 120,
        title: 'File Type',
        field: 'file_type',
        type: PlutoColumnType.text(),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<DownloadRequestProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context);
    final size = MediaQuery.of(context).size;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: size.height - 70,
        width: size.width * 0.8,
        decoration: const BoxDecoration(color: Colors.black26),
        child: PlutoGrid(
          key: UniqueKey(),
          mode: PlutoGridMode.selectWithOneTap,
          configuration: const PlutoGridConfiguration(
            style: PlutoGridStyleConfig.dark(
              activatedBorderColor: Colors.transparent,
              borderColor: Colors.black26,
              gridBorderColor: Colors.black54,
              activatedColor: Colors.black26,
              gridBackgroundColor: Color.fromRGBO(40, 46, 58, 1),
              rowColor: Color.fromRGBO(49, 56, 72, 1),
              checkedColor: Colors.blueGrey,
            ),
          ),
          columns: columns,
          rows: [],
          onLoaded: (event) async {
            PlutoGridUtil.setStateManager(event.stateManager);
            PlutoGridUtil.plutoStateManager
                ?.setSelectingMode(PlutoGridSelectingMode.row);
            if (queueProvider.selectedQueueId == null) {
              provider.fetchRows(
                  HiveBoxes.instance.downloadItemsBox.values.toList());
            } else {
              final queueId = queueProvider.selectedQueueId!;
              final queue =
                  await HiveBoxes.instance.downloadQueueBox.get(queueId);
              if (queue?.downloadItemsIds == null) return;
              final downloads = queue!.downloadItemsIds!
                  .map((e) => HiveBoxes.instance.downloadItemsBox.get(e)!)
                  .toList();
              provider.fetchRows(downloads);
            }
          },
        ),
      ),
    );
  }
}
