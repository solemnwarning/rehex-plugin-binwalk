%define tilde_dist %(echo %{?dist} | tr '.' '~')

Name:     rehex-plugin-binwalk
Version:  PUT_VERSION_HERE
Release:  0%{tilde_dist}
Summary:  Binwalk analysis plugin for the REHex hex editor

License:  GPLv2
URL:      https://www.github.com/solemnwarning/rehex-plugin-binwalk/
Source0:  rehex-plugin-binwalk-%{version}.tar.gz

BuildRequires: make

Requires: rehex
Enhances: rehex

Requires: binwalk
Requires: python3

%description

%prep
%setup -q -n rehex-plugin-binwalk-%{version}

%install
make DESTDIR=%{buildroot} libdir=%{_libdir} install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_libdir}/rehex/
