# exceptions_flutter

The smallest, most load-bearing library in the fleet: a single class,
`ServiceException` (`lib/src/service_exception.dart`) — Equatable,
implements Exception, fields `code` / `message` / `displayMessageKey` /
`stackTrace`. It is the base exception contract for roughly 40 local
packages across the ChargePlus Customer, Partner, and Customer Web
apps, plus `api_request_helper_flutter` itself — all
consuming via UNPINNED git URL with gitignored lock files: anything on
`main` reaches everything on the next `pub get`.

## Blast-radius rules

- Treat the class as additive-only in practice: renaming or removing a
  field, changing nullability, or changing `props` alters equality
  semantics fleet-wide. A truly breaking change requires updating every
  consumer in lockstep — here that means every app AND
  `api_request_helper_flutter` in one coordinated sweep.
- Consumers define domain exceptions extending `ServiceException` and
  dispatch on `code` strings (for example `wrong-password`). This class
  is a pure data carrier — keep it dependency-light (equatable only)
  and free of behavior.

## Verify (CI mirrors `./script.sh` option 3)

- `dart format --line-length 80 --set-exit-if-changed lib test`
- `flutter analyze lib test`
- `very_good test -j 4 --coverage --test-randomize-ordering-seed random`
- CI = VeryGood `flutter_package` workflow (no coverage floor here),
  plus semantic PR titles and a spell check over ALL markdown files —
  a typo in any `.md` fails the build.

## Repo facts

- Git Flow, bare-semver tags (1.0.x). A stray non-semver tag
  `depsUpdate` exists — don't imitate it.
- The MIT badge in the README is stale — no LICENSE file exists.
