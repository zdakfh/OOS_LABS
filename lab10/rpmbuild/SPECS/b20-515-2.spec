Name:          b20-515-2
Version:       1.0
Release:       1%{?dist}
Summary:       Программа студента Bezrukov Daniil группы b20-515
Group:         Testing
License:       GPL
URL:           https://github.com/zdakfh/OOS_LABS
Source0:       %{name}-%{version}.tar.gz
BuildRequires: /bin/rm, /bin/mkdir, /bin/cp
Requires:      /bin/bash, /usr/bin/date
BuildArch:     noarch

%description
A test package

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 b20-515-2 %{buildroot}%{_bindir}
sudo yum install gnuplot

%files
%{_bindir}/b20-515-2

%changelog
* Thu Oct 16 2012 <Bezrukov>
- Added %{_bindir}/b20-515-2
