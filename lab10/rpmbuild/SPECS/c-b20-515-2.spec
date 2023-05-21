Name:       c-b20-515-2
Version:    1.0
Release:    1%{?dist}
Summary:    Программа студента Bezrukov Daniil группы b20-515
Group:      Testing
License:    GPL
URL:        https://github.com/zdakfh/OOS_LABS
Source:     %{name}-%{version}.tar.gz
BuildRequires: gcc

%global debug_package %{nil}

%description
A test package

%prep
%setup -q

%build
gcc -O2 -o c-b20-515-2 c-b20-515-2.c

%install
mkdir -p %{buildroot}%{_bindir}
cp c-b20-515-2 %{buildroot}%{_bindir}
sudo rpm -i ~/rpmbuild/RPMS/noarch/b20-515-2-1.0-1.el9.noarch.rpm --force

%files
%{_bindir}/c-b20-515-2

%changelog
* Thu Oct 16 2012 Bezrukov
- Added %{_bindir}/c-b20-515-2
