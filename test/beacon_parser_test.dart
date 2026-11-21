import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:museum_guide/data/exhibits.dart';
import 'package:museum_guide/services/beacon_service.dart';

void main() {
  group('MAC Address Matching & Beacon Tests', () {
    test('Exhibit lookup by MAC is case-insensitive and supports standard formats', () {
      final ex1 = findExhibitByMac('53:1A:7A:82:B4:83');
      expect(ex1, isNotNull);
      expect(ex1!.id, 'exhibit_1');
      expect(ex1.title, 'Entrance Gate');

      final ex1Lower = findExhibitByMac('53:1a:7a:82:b4:83');
      expect(ex1Lower, isNotNull);
      expect(ex1Lower!.title, 'Entrance Gate');

      final ex2 = findExhibitByMac('76:06:07:E1:A8:C3');
      expect(ex2, isNotNull);
      expect(ex2!.id, 'exhibit_2');
      expect(ex2.title, 'Durbar Hall');

      final ex3 = findExhibitByMac('b5:3a:0c:ba:70:97');
      expect(ex3, isNotNull);
      expect(ex3!.id, 'exhibit_3');
      expect(ex3.title, 'Royal Gallery');

      final unknown = findExhibitByMac('AA:BB:CC:DD:EE:FF');
      expect(unknown, isNull);
    });

    test('Parse raw service UUID correctly (e.g. shared ISC-beacon-v01 service UUID)', () {
      final adv = AdvertisementData(
        advName: 'ISC-beacon-v01',
        txPowerLevel: null,
        appearance: null,
        connectable: false,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [Guid('1a957d0f-78c2-4c95-bfdf-bf483e7b67ac')],
      );

      final uuids = BeaconService.parseUuids(adv);
      expect(uuids, contains('1a957d0f-78c2-4c95-bfdf-bf483e7b67ac'));
    });

    test('Parse iBeacon manufacturer data correctly for raw debug inspection', () {
      final List<int> ibeaconBytes = [
        0x02, 0x15, // iBeacon header
        0x1a, 0x95, 0x7d, 0x0f,
        0x78, 0xc2,
        0x4c, 0x95,
        0xbf, 0xdf,
        0xbf, 0x48, 0x3e, 0x7b, 0x67, 0xac,
        0x00, 0x01, // major
        0x00, 0x02, // minor
        0xc5, // txPower
      ];

      final adv = AdvertisementData(
        advName: 'ISC-beacon-v01',
        txPowerLevel: -59,
        appearance: null,
        connectable: false,
        manufacturerData: {0x004c: ibeaconBytes},
        serviceData: {},
        serviceUuids: [],
      );

      final uuids = BeaconService.parseUuids(adv);
      expect(uuids, contains('1a957d0f-78c2-4c95-bfdf-bf483e7b67ac'));
    });
  });
}
