set -ex

export APPNAME=laundry_room_console
export ARM=arm
export TARGETUSER=$USER
export TARGET=burmilla

# compile
../../flutter-for-pi/bin/flutter packages get # this might not be necessary
../../flutter-for-pi/bin/cache/dart-sdk/bin/dart \
    ../../flutter-for-pi/bin/cache/dart-sdk/bin/snapshots/frontend_server.dart.snapshot \
    --sdk-root ~/dev/flutter-for-pi/bin/cache/artifacts/engine/common/flutter_patched_sdk_product \
    --target=flutter \
    --aot --tfa -Ddart.vm.product=true \
    --packages .packages --output-dill build/kernel_snapshot.dill --depfile build/kernel_snapshot.d \
    package:$APPNAME/main.dart
../../engine-binaries/$ARM/gen_snapshot_linux_x64 \
    --causal_async_stacks --deterministic --snapshot_kind=app-aot-elf \
    --strip --sim_use_hardfp --no-use-integer-division \
    --elf=build/app.so build/kernel_snapshot.dill
../../flutter-for-pi/bin/flutter build bundle --no-tree-shake-icons --precompiled

# upload the application
rsync --recursive build/flutter_assets/ $TARGETUSER@$TARGET:dev/$APPNAME
scp build/app.so $TARGETUSER@$TARGET:dev/$APPNAME/app.so
ssh $TARGETUSER@$TARGET "killall" "flutter-pi" || true
ssh $TARGETUSER@$TARGET "flutter-pi" "--release" "~/dev/$APPNAME"
