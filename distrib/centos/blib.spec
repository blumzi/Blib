Name:           blib
Version:        1.0
Release:        1%{?dist}
Summary:        A bash development framework

License:        BSD2
Source0:        %{name}-%{version}.tgz

Requires:		bash xmlstarlet wget
BuildArch:		noarch

%description

A development framework for bash(1), providing:
 - definition, lookup and inclusion of modules
 - a structured tree for sub-commands
 - debugging and tracing
 - well defined argument passing
 - definition of in-source documentation with man page generation

%prep
%setup -q

%build
#make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
cd usr/share/blib
%make_install
cd ${RPM_BUILD_ROOT}; find . -type f | sed -e "s;^.;;" -e 's;/usr/share/man/.*;&.gz;' > /tmp/%{name}-%{version}.files

%files -f /tmp/%{name}-%{version}.files

%clean
rm /tmp/%{name}-%{version}.files

%postun
/bin/rm -rf @BLIB_BASE@

%changelog
