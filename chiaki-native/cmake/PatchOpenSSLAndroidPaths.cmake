# OpenSSL 1.1.1w's Android NDK detection assumes Unix-style paths. On Windows,
# Strawberry Perl returns paths with backslashes, so clang is not recognized
# and Configure falls back to the GCC toolchain removed from modern NDKs.
if(NOT DEFINED OPENSSL_SOURCE_DIR)
	message(FATAL_ERROR "OPENSSL_SOURCE_DIR must be provided")
endif()

set(android_config "${OPENSSL_SOURCE_DIR}/Configurations/15-android.conf")
file(READ "${android_config}" android_config_contents)

set(old_detection [=[            if (which("clang") =~ m|^$ndk/.*/prebuilt/([^/]+)/|) {]=])
set(new_detection [=[            my $clang = $ENV{CC} // which("clang");
            $ndk =~ s|\\|/|g;
            $clang =~ s|\\|/|g;
            if ($clang =~ m|^$ndk/.*/prebuilt/([^/]+)/|) {]=])

string(FIND "${android_config_contents}" "${old_detection}" detection_position)
if(detection_position EQUAL -1)
	# Update the detection when the ExternalProject source was patched earlier.
	set(old_clang_lookup [=[my $clang = which("clang");]=])
	set(new_clang_lookup [=[my $clang = $ENV{CC} // which("clang");]=])
	string(FIND "${android_config_contents}" "${old_clang_lookup}" patched_position)
	if(patched_position EQUAL -1)
		string(FIND "${android_config_contents}" "${new_clang_lookup}" already_patched_position)
		if(already_patched_position EQUAL -1)
			message(FATAL_ERROR "Could not find OpenSSL 1.1.1 Android NDK detection to patch")
		endif()
	else()
		string(REPLACE "${old_clang_lookup}" "${new_clang_lookup}" android_config_contents "${android_config_contents}")
		file(WRITE "${android_config}" "${android_config_contents}")
	endif()
else()
	string(REPLACE "${old_detection}" "${new_detection}" android_config_contents "${android_config_contents}")
	file(WRITE "${android_config}" "${android_config_contents}")
endif()

# OpenSSL 1.1.1's unix-checker rejects Windows Perl before Android cross
# configuration can run. Its paths are supplied by CMake with forward slashes;
# bypass this host-path sanity check for the Android cross-build only.
set(unix_checker "${OPENSSL_SOURCE_DIR}/Configurations/unix-checker.pm")
file(READ "${unix_checker}" unix_checker_contents)
set(old_unix_check [=[if (rel2abs('.') !~ m|/|) {]=])
set(new_unix_check [=[if (0) {]=])
string(FIND "${unix_checker_contents}" "${old_unix_check}" unix_check_position)
if(NOT unix_check_position EQUAL -1)
	string(REPLACE "${old_unix_check}" "${new_unix_check}" unix_checker_contents "${unix_checker_contents}")
	file(WRITE "${unix_checker}" "${unix_checker_contents}")
endif()
