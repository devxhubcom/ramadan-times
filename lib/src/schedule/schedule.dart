import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_countdown_timer/countdown_timer_controller.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:intl/intl.dart';
import 'package:ramadantimes/l10n/app_localizations.dart';

import 'package:ramadantimes/src/bloc/home/bloc/calendar_bloc.dart';
import 'package:ramadantimes/src/bloc/home/bloc/calendar_event.dart';
import 'package:ramadantimes/src/component/eng_to_bn.dart';

import 'package:ramadantimes/src/models/address/district.dart';

import 'package:ramadantimes/src/models/timing/timing.dart' as timing;
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/home/bloc/calendar_state.dart';

import '../bloc/location/location_cubit.dart';
import '../bloc/location/location_state.dart';
import '../models/timing/timing.dart';
import '../models/timing/timings.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool setReminderForIftar = true;
  District? selectedLocation;
  @override
  void initState() {
    setLocation();
    context.read<LocationCubit>().loadData();
    context.read<HomeBloc>().add(DataFetched(
            date: DateFormat("dd-MM-yyyy").format(
          DateTime.now(),
        )));
    super.initState();
  }

  setLocation() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();

    District d = District.fromJson(
      jsonDecode(
        prefs.getString("current_location") ??
            jsonEncode(
              District(
                  id: "47",
                  division_id: "6",
                  name: "Dhaka",
                  bn_name: "ঢাকা",
                  lat: "23.7115253",
                  lon: "90.4111451",
                  url: "www.dhaka.gov.bd"),
            ),
      ),
    );

    // print(d.bn_name);

    selectedLocation = d;
  }

  @override
  Widget build(BuildContext context) {
    // Intl.defaultLocale = 'es';

    return Scaffold(
      backgroundColor: const Color(0xfff2f2ef),
      appBar: AppBar(
        // toolbarHeight: 70,
        primary: true,
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            height: 36,
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(.1),
                      spreadRadius: 2,
                      blurRadius: 2)
                ]),
            child: BlocBuilder<LocationCubit, LocationState<List<District>>>(
              builder: (context, state) {
                return state.when(idle: () {
                  return Container();
                }, loading: () {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }, data: (data) {
                  return Row(
                    children: [
                      const Icon(Icons.location_pin),
                      const SizedBox(
                        width: 8,
                      ),
                      DropdownButton<District>(
                        hint: AutoSizeText(selectedLocation?.bn_name ?? ""),
                        // value: selectedLocation,
                        borderRadius: BorderRadius.circular(12.r),
                        menuMaxHeight: 600.h,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: data.map(
                          (e) {
                            return DropdownMenuItem(
                                value: e, child: AutoSizeText(e.bn_name));
                          },
                        ).toList(),
                        onChanged: (v) async {
                          setState(() {
                            selectedLocation = v!;
                          });
                          // Obtain shared preferences.
                          final prefs = await SharedPreferences.getInstance();
                          String data = jsonEncode(v);

                          prefs.setString("current_location", data);
                          print("object");
                          if (!mounted) return;
                          context.read<HomeBloc>().add(
                                DataFetched(
                                    date: DateFormat("dd-MM-yyyy").format(
                                      DateTime.now(),
                                    ),
                                    city: v!.name),
                              );
                          print("object1");
                        },
                      ),
                    ],
                  );
                }, error: (e) {
                  return Container();
                });
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          if (!mounted) return;
          context.read<HomeBloc>().add(
                DataFetched(
                    date: DateFormat("dd-MM-yyyy").format(
                      DateTime.now(),
                    ),
                    city: District.fromJson(jsonDecode(
                            preferences.getString("current_location")!))
                        .bn_name),
              );
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, HomeState state) {
            if (state.status == HomeStatus.initial) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            } else if (state.status == HomeStatus.success) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: 16.spMin),
                  ),
                  SliverToBoxAdapter(
                    child: TodayInfoCard(
                      timeOfToday: state.timeOfToday!,
                      timeOfNextDay: state.timeOfNextDay!,
                    ),
                  ),
                  if (state.timeOfToday != null)
                    SliverToBoxAdapter(
                      child: NextPrayer(
                        today: state.timeOfToday!,
                        nextDay: state.timeOfNextDay!,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: GridView(
                      padding: EdgeInsets.only(top: 24.spMin),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12),
                      children: [
                        TimeContainerForSehriTime(
                          time: state.timeOfToday?.data?.timings?.fajr ?? "",
                        ),
                        RemainingTimeContainerForSehriTime(
                          sehriTime:
                              state.timeOfToday?.data?.timings?.fajr ?? "",
                        ),
                        TimeContainerForIftarTime(
                          ifterTime:
                              state.timeOfToday?.data?.timings?.sunset ?? "",
                        ),
                        RemainingTimeContainerForIftarTime(
                          ifterTime:
                              state.timeOfToday?.data?.timings?.sunset ?? "",
                        ),
                      ],
                    ),
                  ),
                  if (state.timeOfNextDay != null)
                    SliverToBoxAdapter(
                      child: NextSehriIftar(
                        data: state.timeOfNextDay!,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                  const SliverToBoxAdapter(
                    child: Dua(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 200),
                  )
                ]),
              );
            } else {
              return SizedBox(
                height: 900.h,
                child: const Center(
                  child: AutoSizeText("Something went Wrong"),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class Dua extends StatefulWidget {
  const Dua({
    super.key,
  });

  @override
  State<Dua> createState() => _DuaState();
}

class _DuaState extends State<Dua> with TickerProviderStateMixin {
  // late TabController _tabController;

  @override
  void initState() {
    // _tabController = TabController(length: 2, vsync: this);

    super.initState();
  }

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> duaList = [
      Container(
        // constraints: BoxConstraints.loose(Size(300, 100)),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            AutoSizeText(
              "نَوَيْتُ اَنْ اُصُوْمَ غَدًا مِّنْ شَهْرِ رَمْضَانَ الْمُبَارَكِ فَرْضَا لَكَ يَا اللهُ فَتَقَبَّل مِنِّى اِنَّكَ اَنْتَ السَّمِيْعُ الْعَلِيْم",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.right,
            ),
            AutoSizeText(
              "উচ্চারণ : নাওয়াইতু আন আছুমা গদাম মিং শাহরি রমাদ্বানাল মুবারকি ফারদ্বল্লাকা ইয়া আল্লাহু ফাতাক্বব্বাল মিন্নী ইন্নাকা আংতাস সামীউল আলীম",
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AutoSizeText(
              "অর্থ : হে আল্লাহ! আমি আগামীকাল পবিত্র রমজানের তোমার পক্ষ থেকে নির্ধারিত ফরজ রোজা রাখার ইচ্ছা পোষণ (নিয়্যত) করলাম। অতএব তুমি আমার পক্ষ থেকে (আমার রোযা তথা পানাহার থেকে বিরত থাকাকে) কবুল কর, নিশ্চয়ই তুমি সর্বশ্রোতা ও সর্বজ্ঞানী।",
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      Container(
        // constraints: BoxConstraints.loose(Size(300, 100)),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            AutoSizeText(
              "اَللَّهُمَّ لَكَ صُمْتُ وَ عَلَى رِزْقِكَ وَ اَفْطَرْتُ بِرَحْمَتِكَ يَا اَرْحَمَ الرَّاحِيْمِيْن",
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AutoSizeText(
              "উচ্চারণ : আল্লাহুম্মা লাকা ছুমতু ওয়া আলা রিযক্বিকা ওয়া আফতারতু বিরাহমাতিকা ইয়া আরহামার রাহিমিন",
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AutoSizeText(
              "অর্থ : হে আল্লাহ! আমি তোমারই সন্তুষ্টির জন্য রোজা রেখেছি এবং তোমারই দেয়া রিযিক্বের মাধ্যমে ইফতার করছি।",
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.only(
        top: 16,
      ),
      // height: ,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xff6348EB),
          const Color(0xff6348EB).withOpacity(0),
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        color: const Color(0xff6348eb),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6),
              // width: 200,
              // height: 48,
              decoration: BoxDecoration(
                // border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // controller: _tabController,
                // indicatorSize: TabBarIndicatorSize.tab,
                // labelColor: const Color(0xff6348eb),
                // unselectedLabelColor: Colors.white,
                // indicator: const BoxDecoration(color: Colors.transparent),
                // labelPadding: EdgeInsets.zero,
                // onTap: (value) {
                //   setState(() {
                //     _selectedTab = value;
                //   });
                // },
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: _selectedTab == 0
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        child: AutoSizeText(
                          AppLocalizations.of(context)?.sehriDua ?? "",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == 0
                                      ? const Color(0xff6348EB)
                                      : Colors.white),
                        )),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: _selectedTab == 1 ? Colors.white : null,
                        ),
                        child: AutoSizeText(
                          AppLocalizations.of(context)?.ifterDua ?? "",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == 1
                                      ? const Color(0xff6348EB)
                                      : Colors.white),
                        )),
                  ),
                ],
              )),
          SizedBox(
            height: 16.spMin,
          ),
          duaList[_selectedTab],
        ],
      ),
    );
  }
}

class TimeContainerForSehriTime extends StatefulWidget {
  const TimeContainerForSehriTime({
    super.key,
    required this.time,
  });
  final String time;

  @override
  State<TimeContainerForSehriTime> createState() =>
      _TimeContainerForSehriTimeState();
}

class _TimeContainerForSehriTimeState extends State<TimeContainerForSehriTime> {
  bool setReminderForSehri = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: MediaQuery.of(context).size.width / 2,
          width: MediaQuery.of(context).size.width / 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xffE3DeFF),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  AppLocalizations.of(context)?.sehriTime ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.47,
                      fontWeight: FontWeight.bold),
                ),
                AutoSizeText.rich(
                  TextSpan(
                    text: DateFormat.jm("bn_BD").format(
                      DateTime(
                              2023,
                              1,
                              1,
                              int.parse(widget.time.split(":").first),
                              int.parse(widget.time.split(":").last))
                          .subtract(const Duration(minutes: 5)),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.4,
                        color: const Color(0xff674CEC),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 24.spMin,
                  // width: 36,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: CupertinoSwitch(
                        activeColor: const Color(0xff6348eb),
                        trackColor: Colors.blueGrey.shade50,
                        value: setReminderForSehri,
                        onChanged: (v) {
                          setState(() {
                            setReminderForSehri = v;
                          });
                        }),
                  ),
                )
              ]),
        ),
        Positioned(
          bottom: 20,
          right: 8,
          child: Image.asset(
            "assets/images/sehriMoon.png",
            height: 60,
            width: 60.w,
          ),
        )
      ],
    );
  }
}

class TimeContainerForIftarTime extends StatefulWidget {
  const TimeContainerForIftarTime({
    super.key,
    required this.ifterTime,
  });
  final String ifterTime;

  @override
  State<TimeContainerForIftarTime> createState() =>
      _TimeContainerForIftarTimeState();
}

class _TimeContainerForIftarTimeState extends State<TimeContainerForIftarTime> {
  bool setReminderForSehri = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: MediaQuery.of(context).size.width / 2,
          width: MediaQuery.of(context).size.width / 2,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xffFFEABF),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  AppLocalizations.of(context)?.ifterTime ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.47,
                      color: const Color(0xff1C1646),
                      fontWeight: FontWeight.w700),
                ),
                AutoSizeText.rich(
                  TextSpan(
                    text: DateFormat.jm("bn_BD").format(
                      DateTime(
                              2023,
                              1,
                              1,
                              int.parse(widget.ifterTime.split(":").first),
                              int.parse(widget.ifterTime.split(":").last))
                          .add(const Duration(minutes: 4)),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.4,
                        color: const Color(0xff674cec),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 24.spMin,
                  // width: 36,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: CupertinoSwitch(
                        activeColor: const Color(0xff6348eb),
                        trackColor: Colors.blueGrey.shade50,
                        value: setReminderForSehri,
                        onChanged: (v) {
                          setState(() {
                            setReminderForSehri = v;
                          });
                        }),
                  ),
                )
              ]),
        ),
        Positioned(
          bottom: 20,
          right: 8,
          child: Image.asset(
            "assets/images/iftarCloud.png",
            height: 60,
            width: 60.w,
          ),
        )
      ],
    );
  }
}

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
  late DateTime endTime;
  late DateTime nextDayEndTime;

  @override
  void initState() {
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

    controller =
        CountdownTimerController(endTime: endTime.millisecondsSinceEpoch);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                  AppLocalizations.of(context)?.remaining ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.4,
                      color: const Color(0xffffb82c),
                      fontWeight: FontWeight.bold),
                ),
                AutoSizeText(
                  AppLocalizations.of(context)?.ofIfter ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 14.sp,
                        height: 1.4,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  late CountdownTimerController controller;
  late DateTime endTime;
  late DateTime nextDayEndTime;

  @override
  void initState() {
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

    controller =
        CountdownTimerController(endTime: endTime.millisecondsSinceEpoch);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  AppLocalizations.of(context)?.remaining ?? "",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      height: 1.47,
                      color: const Color(0xffffb82c),
                      fontWeight: FontWeight.bold),
                ),
                AutoSizeText(
                  AppLocalizations.of(context)?.ofSehri ?? "",
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

class NextPrayer extends StatelessWidget {
  const NextPrayer({
    super.key,
    required this.today,
    required this.nextDay,
  });
  final timing.Timing today;
  final timing.Timing nextDay;

  Map<String, dynamic> getNextPrayer(Timings today, Timings nextDay) {
    if (DateTime.now().isBefore(customHourMinuteOfToday(
      int.parse(
        today.fajr!.split(":").first,
      ),
      int.parse(
        today.fajr!.split(":").last,
      ),
    ))) {
      return {
        "start_minute": today.fajr?.split(":").last ?? "",
        "start_hour": today.fajr?.split(":").first ?? "",
        "end_minute": today.sunrise?.split(":").last ?? "",
        "end_hour": today.sunrise?.split(":").first ?? "",
        "name": "Fajr"
      };
    } else if (DateTime.now().isBefore(customHourMinuteOfToday(
      int.parse(
        today.dhuhr!.split(":").first,
      ),
      int.parse(
        today.dhuhr!.split(":").last,
      ),
    ))) {
      return {
        "start_minute": today.dhuhr?.split(":").last ?? "",
        "start_hour": today.dhuhr?.split(":").first ?? "",
        "end_minute": today.asr?.split(":").last ?? "",
        "end_hour": today.asr?.split(":").first ?? "",
        "name": "Dhuhr"
      };
    } else if (DateTime.now().isBefore(customHourMinuteOfToday(
      int.parse(
        today.asr!.split(":").first,
      ),
      int.parse(
        today.asr!.split(":").last,
      ),
    ))) {
      return {
        "start_minute": today.asr?.split(":").last ?? "",
        "start_hour": today.asr?.split(":").first ?? "",
        "end_minute": today.sunset?.split(":").last ?? "",
        "end_hour": today.sunset?.split(":").first ?? "",
        "name": "Asr"
      };
    } else if (DateTime.now().isBefore(customHourMinuteOfToday(
      int.parse(
        today.maghrib!.split(":").first,
      ),
      int.parse(
        today.maghrib!.split(":").last,
      ),
    ))) {
      return {
        "start_minute": today.maghrib?.split(":").last ?? "",
        "start_hour": today.maghrib?.split(":").first ?? "",
        "end_minute": today.isha?.split(":").last ?? "",
        "end_hour": today.isha?.split(":").first ?? "",
        "name": "Maghrib"
      };
    } else if (DateTime.now().isBefore(customHourMinuteOfToday(
      int.parse(
        today.isha!.split(":").first,
      ),
      int.parse(
        today.isha!.split(":").last,
      ),
    ))) {
      return {
        "start_minute": today.isha?.split(":").last ?? "",
        "start_hour": today.isha?.split(":").first ?? "",
        "end_minute": nextDay.fajr?.split(":").last ?? "",
        "end_hour": nextDay.fajr?.split(":").first ?? "",
        "name": "Isha"
      };
    } else {
      return {
        "start_minute": today.fajr?.split(":").last ?? "",
        "start_hour": today.fajr?.split(":").first ?? "",
        "end_minute": today.sunrise?.split(":").last ?? "",
        "end_hour": today.sunrise?.split(":").first ?? "",
        "name": "Fajr"
      };
    }
  }

  DateTime customHourMinuteOfToday(int hour, int minute) {
    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 1, right: 1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xffD9DFE0),
            const Color(0xffD9DFE0).withOpacity(0),
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          color: Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                AppLocalizations.of(context)?.nextPrayer ?? "",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AutoSizeText(
                AppLocalizations.of(context)?.prayerName(
                      getNextPrayer(today.data!.timings!,
                              nextDay.data!.timings!)['name'] ??
                          "",
                    ) ??
                    "",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xffffa600), height: 1, fontSize: 20.sp),
              )
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: const Color(0xfff2f2f7),
                borderRadius: BorderRadius.circular(15.r)),
            child: AutoSizeText.rich(
              TextSpan(
                  text: DateFormat.jm("bn_BD").format(
                    DateTime(
                      2023,
                      1,
                      1,
                      int.tryParse(getNextPrayer(today.data!.timings!,
                              nextDay.data!.timings!)["start_hour"]) ??
                          0,
                      int.tryParse(getNextPrayer(today.data!.timings!,
                              nextDay.data!.timings!)["start_minute"]) ??
                          0,
                    ),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                  children: [
                    // TextSpan(
                    //     text: "AM",
                    //     style: Theme.of(context).textTheme.bodySmall),
                    TextSpan(
                        text: " - ",
                        style: Theme.of(context).textTheme.titleLarge),
                    TextSpan(
                      text: DateFormat.jm("bn_BD").format(
                        DateTime(
                          2023,
                          1,
                          1,
                          int.tryParse(getNextPrayer(today.data!.timings!,
                                  nextDay.data!.timings!)["end_hour"]) ??
                              0,
                          int.tryParse(getNextPrayer(today.data!.timings!,
                                  nextDay.data!.timings!)["end_minute"]) ??
                              0,
                        ),
                      ),
                    ),
                  ]),
            ),
          )
        ],
      ),
    );
  }
}

class CurrentPrayer extends StatelessWidget {
  const CurrentPrayer({
    super.key,
    required this.today,
    required this.nextDay,
  });
  final timing.Timing today;
  final timing.Timing nextDay;

  Map<String, dynamic> getCurrentPrayer(Timings today, Timings nextDay) {
    if (DateTime.now().isAfter(customHourMinuteOfToday(
          00,
          00,
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.fajr!.split(":").first,
          ),
          int.parse(
            today.fajr!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.isha?.split(":").last ?? "",
        "start_hour": today.isha?.split(":").first ?? "",
        "end_minute": today.fajr?.split(":").last ?? "",
        "end_hour": today.fajr?.split(":").first ?? "",
        "name": "Isha"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.fajr!.split(":").first,
          ),
          int.parse(
            today.fajr!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.sunrise!.split(":").first,
          ),
          int.parse(
            today.sunrise!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.fajr?.split(":").last ?? "",
        "start_hour": today.fajr?.split(":").first ?? "",
        "end_minute": today.sunrise?.split(":").last ?? "",
        "end_hour": today.sunrise?.split(":").first ?? "",
        "name": "Fajr"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.sunrise!.split(":").first,
          ),
          int.parse(
            today.sunrise!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.dhuhr!.split(":").first,
          ),
          int.parse(
            today.dhuhr!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.sunrise?.split(":").last ?? "",
        "start_hour": today.sunrise?.split(":").first ?? "",
        "end_minute": today.dhuhr?.split(":").last ?? "",
        "end_hour": today.dhuhr?.split(":").first ?? "",
        "name": "Ishrak"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.dhuhr!.split(":").first,
          ),
          int.parse(
            today.dhuhr!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.asr!.split(":").first,
          ),
          int.parse(
            today.asr!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.dhuhr?.split(":").last ?? "",
        "start_hour": today.dhuhr?.split(":").first ?? "",
        "end_minute": today.asr?.split(":").last ?? "",
        "end_hour": today.asr?.split(":").first ?? "",
        "name": "Dhuhr"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.asr!.split(":").first,
          ),
          int.parse(
            today.asr!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.maghrib!.split(":").first,
          ),
          int.parse(
            today.maghrib!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.asr?.split(":").last ?? "",
        "start_hour": today.asr?.split(":").first ?? "",
        "end_minute": today.maghrib?.split(":").last ?? "",
        "end_hour": today.maghrib?.split(":").first ?? "",
        "name": "Asr"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.maghrib!.split(":").first,
          ),
          int.parse(
            today.maghrib!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(customHourMinuteOfToday(
          int.parse(
            today.isha!.split(":").first,
          ),
          int.parse(
            today.isha!.split(":").last,
          ),
        ))) {
      return {
        "start_minute": today.maghrib?.split(":").last ?? "",
        "start_hour": today.maghrib?.split(":").first ?? "",
        "end_minute": today.isha?.split(":").last ?? "",
        "end_hour": today.isha?.split(":").first ?? "",
        "name": "Maghrib"
      };
    } else if (DateTime.now().isAfter(customHourMinuteOfToday(
          int.parse(
            today.isha!.split(":").first,
          ),
          int.parse(
            today.isha!.split(":").last,
          ),
        )) &&
        DateTime.now().isBefore(
          customHourMinuteOfToday(
            00,
            00,
          ),
        )) {
      return {
        "start_minute": today.isha?.split(":").last ?? "",
        "start_hour": today.isha?.split(":").first ?? "",
        "end_minute": nextDay.fajr?.split(":").last ?? "",
        "end_hour": nextDay.fajr?.split(":").first ?? "",
        "name": "Isha"
      };
    } else {
      return {
        "start_minute": today.isha?.split(":").last ?? "",
        "start_hour": today.isha?.split(":").first ?? "",
        "end_minute": nextDay.fajr?.split(":").last ?? "",
        "end_hour": nextDay.fajr?.split(":").first ?? "",
        "name": "Isha"
      };
    }
  }

  DateTime customHourMinuteOfToday(int hour, int minute) {
    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
  }

  DateTime customHourMinuteOfNextDay(int hour, int minute) {
    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day + 1, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              "${AppLocalizations.of(context)?.prayerName(
                    getCurrentPrayer(today.data!.timings!,
                            nextDay.data!.timings!)['name'] ??
                        "",
                  ) ?? ""} ${AppLocalizations.of(context)?.prayer}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xff000000),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600),
            ),
            CountdownTimer(
              endTime: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                int.parse(getCurrentPrayer(
                    today.data!.timings!, nextDay.data!.timings!)["end_hour"]),
                int.parse(getCurrentPrayer(today.data!.timings!,
                    nextDay.data!.timings!)["end_minute"]),
              ).millisecondsSinceEpoch,
              onEnd: () async {
                SharedPreferences preferences =
                    await SharedPreferences.getInstance();

                context.read<HomeBloc>().add(
                      DataFetched(
                          date: DateFormat("dd-MM-yyyy").format(
                            DateTime.now(),
                          ),
                          city: District.fromJson(jsonDecode(
                                  preferences.getString("current_location")!))
                              .bn_name),
                    );
              },
              widgetBuilder: (_, CurrentRemainingTime? time) {
                if (time == null) {
                  return const Text("");
                }
                return Row(
                  children: [
                    AutoSizeText(
                      "${AppLocalizations.of(context)?.timeRemaining ?? ""} ",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xff6348EB),
                          fontWeight: FontWeight.w600),
                    ),
                    AutoSizeText(
                      AppLocalizations.of(context)?.localeName == "bn"
                          ? engToBn(
                              '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}')
                          : '${time.hours?.toString().padLeft(2, "0") ?? "00"} : ${time.min?.toString().padLeft(2, "0") ?? "00"} : ${time.sec.toString().padLeft(2, "0")}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xff6348EB),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ],
    );
  }
}

class NextSehriIftar extends StatelessWidget {
  const NextSehriIftar({
    super.key,
    required this.data,
  });
  final timing.Timing data;

  @override
  Widget build(BuildContext context) {
    // context.read<NextDayTimingCubit>().loadNextData();
    return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xffD9DFE0),
              const Color(0xffFFFFFF).withOpacity(0),
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            color: Colors.white,
            borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      AppLocalizations.of(context)?.nextDay ?? "",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(),
                    ),
                    AutoSizeText(
                      AppLocalizations.of(context)?.sehri ?? "",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xffffa600),
                          height: 1,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700),
                    )
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                      color: const Color(0xfff2f2f7),
                      borderRadius: BorderRadius.circular(15)),
                  child: AutoSizeText.rich(
                    TextSpan(
                      text: DateFormat.jm("bn_BD").format(
                        DateTime(
                                2023,
                                1,
                                1,
                                int.parse(data.data?.timings?.fajr
                                        ?.split(":")
                                        .first ??
                                    "0"),
                                int.parse(
                                    data.data?.timings?.fajr?.split(":").last ??
                                        "0"))
                            .subtract(const Duration(minutes: 5)),
                      ),

                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xffffa600),
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp),
                      // children: [
                      // TextSpan(
                      //     text: "AM",
                      //     style: Theme.of(context)
                      //         .textTheme
                      //         .bodySmall
                      //         ?.copyWith(
                      //             color: const Color(0xffffa600))),
                      // ],
                    ),
                  ),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      AppLocalizations.of(context)?.nextDay ?? "",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AutoSizeText(
                      AppLocalizations.of(context)?.ifter ?? "",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xff674cec),
                          height: 1,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp),
                    )
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                      color: const Color(0xffD9DFE0).withOpacity(.54),
                      borderRadius: BorderRadius.circular(15)),
                  child: AutoSizeText.rich(
                    TextSpan(
                      text: DateFormat.jm("bn_BD").format(
                        DateTime(
                                2023,
                                1,
                                1,
                                int.parse(data.data?.timings?.maghrib
                                        ?.split(":")
                                        .first ??
                                    "0"),
                                int.parse(data.data?.timings?.maghrib
                                        ?.split(":")
                                        .last ??
                                    "0"))
                            .add(const Duration(minutes: 4)),
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xff674cec),
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp),
                    ),
                  ),
                )
              ],
            ),
          ],
        ));
  }
}

class TodayInfoCard extends StatefulWidget {
  final Timing timeOfToday;
  final Timing timeOfNextDay;
  const TodayInfoCard({
    super.key,
    required this.timeOfToday,
    required this.timeOfNextDay,
  });

  @override
  State<TodayInfoCard> createState() => _TodayInfoCardState();
}

class _TodayInfoCardState extends State<TodayInfoCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 200,
      width: 375.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xffC2CFF2),
          const Color(0xffF8E99B).withOpacity(0)
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        color: const Color(0xffe3deff),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),

              Container(
                // height: 100,
                width: 200,
                padding: EdgeInsets.only(right: 0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AutoSizeText(
                      AppLocalizations.of(context)!.localeName == "bn"
                          ? engToBn(AppLocalizations.of(context)?.arabicDate(
                                  (int.parse(widget.timeOfToday.data?.date?.hijri?.day ?? "") -
                                          1)
                                      .toString(),
                                  widget.timeOfToday.data?.date?.hijri?.month
                                          ?.number
                                          .toString() ??
                                      "",
                                  widget.timeOfToday.data?.date?.hijri?.year ??
                                      "") ??
                              "")
                          : AppLocalizations.of(context)?.arabicDate(
                                  widget.timeOfToday.data?.date?.hijri?.day ??
                                      "",
                                  widget.timeOfToday.data?.date?.hijri?.month?.en
                                          .toString() ??
                                      "",
                                  widget.timeOfToday.data?.date?.hijri?.year ??
                                      "") ??
                              "",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          height: 1.4,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff36219E)),
                    ),
                    AutoSizeText(
                      DateFormat("EEEE, dd MMMM", "bn").format(DateTime.now()),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Image.asset(
              //   "assets/images/image1.png",
              //   height: 80,
              //   width: 110.w,
              // ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              CurrentPrayer(
                  today: widget.timeOfToday, nextDay: widget.timeOfNextDay),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      AutoSizeText(
                        "${AppLocalizations.of(context)?.prayerName("Sunrise") ?? ""}  ",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xff6348EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp),
                      ),
                      AutoSizeText(
                        DateFormat.jm("bn_BD").format(DateTime(
                            2023,
                            1,
                            1,
                            int.parse(widget.timeOfToday.data?.timings?.sunrise
                                    ?.split(":")
                                    .first ??
                                "0"),
                            int.parse(widget.timeOfToday.data?.timings?.sunrise
                                    ?.split(":")
                                    .last ??
                                "0"))),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xff6348EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      AutoSizeText(
                        "${AppLocalizations.of(context)?.prayerName("Sunset") ?? ""}  ",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 14.sp),
                      ),
                      AutoSizeText(
                        DateFormat.jm("bn_BD").format(DateTime(
                            2023,
                            1,
                            1,
                            int.parse(widget.timeOfToday.data?.timings?.sunset
                                    ?.split(":")
                                    .first ??
                                "0"),
                            int.parse(widget.timeOfToday.data?.timings?.sunset
                                    ?.split(":")
                                    .last ??
                                "0")))
                        // engToBn(
                        //   widget.timeOfToday.data?.timings?.sunset ?? "",
                        // ),
                        ,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
