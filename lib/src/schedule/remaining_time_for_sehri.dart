import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../component/eng_to_bn.dart';

class RemainingTimeContainerForSehriTime extends StatefulWidget {
  const RemainingTimeContainerForSehriTime({
    super.key,
    required this.sehriTime,
  });
  final String sehriTime;

  @override
  State<RemainingTimeContainerForSehriTime> createState() =>
      _RemainingTimeContainerForSehriTimeState();
}

class _RemainingTimeContainerForSehriTimeState
    extends State<RemainingTimeContainerForSehriTime> {
  bool setReminderForSehri = true;

  // late CountdownTimerController controller;
  late DateTime endTime;
  late DateTime nextDayEndTime;

  @override
  void initState() {
    // controller =
    //     CountdownTimerController(endTime: endTime.millisecondsSinceEpoch);
    super.initState();
  }

  @override
  void dispose() {
    // controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    endTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      int.parse(widget.sehriTime.toString().split(":").first),
      int.parse(widget.sehriTime.toString().split(":").last) - 5,
    );
    nextDayEndTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 1,
      int.parse(widget.sehriTime.toString().split(":").first),
      int.parse(widget.sehriTime.toString().split(":").last) - 5,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: MediaQuery.of(context).size.width / 2,
          width: MediaQuery.of(context).size.width / 2,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xff36219e),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  AppLocalizations.of(context)?.ofSehri ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.47,
                      color: const Color(0xffffb82c),
                      fontWeight: FontWeight.bold),
                ),
                AutoSizeText(
                  AppLocalizations.of(context)?.remaining ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (DateTime.now().isBefore(endTime))
                  CountdownTimer(
                    endTime: endTime.millisecondsSinceEpoch,
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
                if (DateTime.now().isAfter(endTime))
                  CountdownTimer(
                    endTime: nextDayEndTime.millisecondsSinceEpoch,
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
