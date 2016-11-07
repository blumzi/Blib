Name:           blib
Version:        1.0
Release:        1%{?dist}
Summary:        A bash development framework

License:        BSD          
Source0:        

BuildRequires:  
Requires:       

%description
A development framework for bash(1).

%prep
%setup -q


%build
%configure
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
%make_install


%files
%doc



%changelog
