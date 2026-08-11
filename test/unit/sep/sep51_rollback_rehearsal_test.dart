import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Frozen SEP-0051 renderings of two transaction envelopes.
//
// The XDR-JSON a type renders to is derived from the `.x` files, so an XDR
// revision can legitimately move it. SEP-0051 §Breaking Changes says as much.
// Nothing else in this repository would report such a move as anything but a
// regenerated file, and a wire-format change that arrives unannounced is a
// change users discover in production.
//
// The two constants below are that announcement. Each pins one value in both
// directions, byte for byte, so a change to the rendering fails here first and
// has to be made deliberately.
//
// Provenance. Both pairs come from the reference implementation named in
// SEP-0051, `stellar-xdr 28.0.0` (tool commit d0f1330e43c3a2c0c616da30698b24140d4eea72,
// vendored XDR 9c9c145953e80990d6ff1ae3a6a973a0ce6d0694), driven as:
//
//   echo '<base64>' | stellar-xdr decode --type TransactionEnvelope \
//       --input single-base64 --output json
//   echo '<json>'   | stellar-xdr encode --type TransactionEnvelope
//
// The second command returns the base64 the first was given, so each pair is
// the reference's own fixed point rather than one side of a conversion.

/// What a maintainer has to do when one of these assertions fails.
const String frozenRenderingGuidance =
    'This is a frozen SEP-0051 rendering. If the XDR revision this SDK '
    'generates from has moved, the new rendering is correct: re-derive the '
    'constant from the pinned reference build, replace it here, and record the '
    'wire-format change in CHANGELOG.md so users meet it before their '
    'integrations do. If the XDR revision has not moved, the rendering has '
    'regressed and the generator is what needs fixing.';

/// A payment of a credit asset, with a text memo, time bounds and one
/// signature.
///
/// Crosses the classic surface: the envelope union, a `v1` transaction, a
/// muxed account rendered as a G-strkey, a sequence number and an amount as
/// base-10 strings, the escape ladder over memo text, an `AlphaNum4` code with
/// its NUL padding trimmed, and a signature as hex.
const String classicEnvelopeXdr =
    'AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw=';

const String classicEnvelopeJson =
    '{"tx":{"tx":{"source_account":"GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN","fee":100,"seq_num":"46489056724385793","cond":{"time":{"min_time":"1535756672","max_time":"1567292672"}},"memo":{"text":"Enjoy this transaction"},"operations":[{"source_account":null,"body":{"payment":{"destination":"GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O","asset":{"credit_alphanum4":{"asset_code":"USD","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}},"amount":"400004000"}}}],"ext":"v0"},"signatures":[{"hint":"4aa07ed0","signature":"defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c"}]}}';

/// A contract creation from an asset, carrying Soroban transaction data.
///
/// Crosses the Soroban surface: an `invoke_host_function` operation, a
/// contract identifier preimage, an `AlphaNum12` code, a void arm rendered as
/// a bare string, the `v1` transaction extension, a ledger footprint holding a
/// contract data key with a C-strkey, and a resource fee as a base-10 string.
const String sorobanEnvelopeXdr =
    'AAAAAgAAAABxW9E8HvJ8y/Uo60YQVQRdVxbZXkyyqJC//cKccViIQgBivo0AHeDLAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAACU09ORVNPAAAAAAAAAAAAAHFb0Twe8nzL9SjrRhBVBF1XFtleTLKokL/9wpxxWIhCAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAF2AfJVgDq1MvSnUdklLI+KInZbJj/1BbL2GfVMBtwTKQAAABQAAAABAAK6lgAAAAAAAAHoAAAAAABivikAAAABcViIQgAAAEBSslktJS0iD3ObWkvXUQetp459tfnQyL3acMFhdl9H7wmUCj6UWzvZmt/X5mt/wmJlxnsyHBX6TkQv4jFkIWcG';

const String sorobanEnvelopeJson =
    '{"tx":{"tx":{"source_account":"GBYVXUJ4D3ZHZS7VFDVUMECVAROVOFWZLZGLFKEQX764FHDRLCEEFWPY","fee":6471309,"seq_num":"8409936807591938","cond":"none","memo":"none","operations":[{"source_account":null,"body":{"invoke_host_function":{"host_function":{"create_contract":{"contract_id_preimage":{"asset":{"credit_alphanum12":{"asset_code":"SONESO","issuer":"GBYVXUJ4D3ZHZS7VFDVUMECVAROVOFWZLZGLFKEQX764FHDRLCEEFWPY"}}},"executable":"stellar_asset"}},"auth":[]}}}],"ext":{"v1":{"ext":"v0","resources":{"footprint":{"read_only":[],"read_write":[{"contract_data":{"contract":"CB3AD4SVQA5LKMXUU5I5SJJMR6FCE5S3EY77KBNS6YM7KTAG3QJSSGGO","key":"ledger_key_contract_instance","durability":"persistent"}}]},"instructions":178838,"disk_read_bytes":0,"write_bytes":488},"resource_fee":"6471209"}}},"signatures":[{"hint":"71588842","signature":"52b2592d252d220f739b5a4bd75107ada78e7db5f9d0c8bdda70c161765f47ef09940a3e945b3bd99adfd7e66b7fc26265c67b321c15fa4e442fe23164216706"}]}}';

void main() {
  group('SEP-0051 frozen rendering of a classic transaction envelope', () {
    test('renders the frozen XDR to the frozen JSON', () {
      expect(
        XdrTransactionEnvelope.fromBase64EncodedXdrString(
          classicEnvelopeXdr,
        ).toXdrJson(),
        classicEnvelopeJson,
        reason: frozenRenderingGuidance,
      );
    });

    test('reads the frozen JSON back to the frozen XDR', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(
          classicEnvelopeJson,
        ).toBase64EncodedXdrString(),
        classicEnvelopeXdr,
        reason: frozenRenderingGuidance,
      );
    });

    test('renders what it reads, with no second canonical form', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(classicEnvelopeJson).toXdrJson(),
        classicEnvelopeJson,
        reason: frozenRenderingGuidance,
      );
    });
  });

  group('SEP-0051 frozen rendering of a Soroban transaction envelope', () {
    test('renders the frozen XDR to the frozen JSON', () {
      expect(
        XdrTransactionEnvelope.fromBase64EncodedXdrString(
          sorobanEnvelopeXdr,
        ).toXdrJson(),
        sorobanEnvelopeJson,
        reason: frozenRenderingGuidance,
      );
    });

    test('reads the frozen JSON back to the frozen XDR', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(
          sorobanEnvelopeJson,
        ).toBase64EncodedXdrString(),
        sorobanEnvelopeXdr,
        reason: frozenRenderingGuidance,
      );
    });

    test('renders what it reads, with no second canonical form', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(sorobanEnvelopeJson).toXdrJson(),
        sorobanEnvelopeJson,
        reason: frozenRenderingGuidance,
      );
    });
  });
}
