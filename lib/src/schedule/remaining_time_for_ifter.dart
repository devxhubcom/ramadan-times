import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../bloc/home/bloc/calendar_bloc.dart';
import '../bloc/home/bloc/calendar_event.dart';
import '../component/eng_to_bn.dart';
import '../models/address/district.dart';

class RemainingTimeContainerForIftarTime extends StatefulWidget {
  const RemainingTimeContainerForIftarTime({
    super.key,
    required this.ifterTime,
  });
  final String ifterTime;

  @override
  State<RemainingTimeContainerForIftarTime> createState() =>
      _RemainingTimeContainerForIftarTimeState();
}

class _RemainingTimeContainerForIftarTimeState
    extends State<RemainingTimeContainerForIftarTime> {
  bool setReminderForSehri = true;
  late CountdownTimerController controller;
  DateTime? endTime;
  DateTime? nextDayEndTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    endTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      int.parse(widget.ifterTime.toString().split(":").first),
      int.parse(widget.ifterTime.toString().split(":").last) + 4,
    );
    nextDayEndTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 1,
      int.parse(widget.ifterTime.toString().split(":").first),
      int.parse(widget.ifterTime.toString().split(":").last) + 4,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: MediaQuery.of(context).size.width / 2,
          width: MediaQuery.of(context).size.width / 2,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xff8269FF),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  AppLocalizations.of(context)?.ofIfter ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                AutoSizeText(
                  AppLocalizations.of(context)?.remaining ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 14.sp,
                        height: 1.4,
                        color:  Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (DateTime.now().isBefore(endTime!))
                  CountdownTimer(
                    onEnd: () async {
                      SharedPreferences preferences =
                          await SharedPreferences.getInstance();

                      context.read<HomeBloc>().add(
                            DataFetched(
                                date: DateFormat("dd-MM-yyyy").format(
                                  DateTime.now(),
                                ),
                                city: District.fromJson(jsonDecode(preferences
                                        .getString("current_location")!))
                                    .bn_name),
                          );
                    },
                    endTime: endTime!.millisecondsSinceEpoch,
                    widgetBuilder: (_, CurrentRemainingTime? time) {
                      if (time == null) {
                        return const Text("");
                      }
                      return AutoSizeText(
                        AppLocalizations.of(context)?.localeName == "bn"
                            ? engToBn(
                                '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}')
                            : '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                if (DateTime.now().isAfter(endTime!))
                  CountdownTimer(
                    endTime: nextDayEndTime!.millisecondsSinceEpoch,
                    widgetBuilder: (_, CurrentRemainingTime? time) {
                      if (time == null) {
                        return const Text("");
                      }
                      return AutoSizeText(
                        AppLocalizations.of(context)?.localeName == "bn"
                            ? engToBn(
                                '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}')
                            : '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700),
                      );
                    },
                  ),
              ]),
        ),
        Positioned(
          // bottom: 20,
          right: 8,
          child: Image.asset(
            "assets/images/timer.png",
            height: 60,
            width: 60.w,
          ),
        )
      ],
    );
  }
}
