%define tilde_dist %(echo %{?dist} | tr '.' '~')

Name:     rehex-plugin-binwalk
Version:  PUT_VERSION_HERE
Release:  0%{tilde_dist}+1
Summary:  Binwalk analysis plugin for the REHex hex editor

License:  GPLv2
URL:      https://www.github.com/solemnwarning/rehex-plugin-binwalk/
Source0:  rehex-plugin-binwalk-%{version}.tar.gz

BuildRequires: make

Requires: rehex >= 0.62.0-0~
Enhances: rehex

Requires: binwalk
Requires: python3

%description

# This package doesn't have any binaries in it, but the RPM build process under Fedora 41 chokes
# while trying to prepare a debugsource package, so we skip it.
#
# "Empty %files file /builddir/build/BUILD/rehex-plugin-binwalk-1.0-build/rehex-plugin-binwalk-1.0/debugsourcefiles.list"
%global debug_package %{nil}

%prep
%setup -q -n rehex-plugin-binwalk-%{version}

%install
make DESTDIR=%{buildroot} libdir=%{_libdir} install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_libdir}/rehex/
