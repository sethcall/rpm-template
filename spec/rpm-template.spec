%{!?project_release: %define project_release 1}
%{!?project_version: %define project_version master}
%{!?project_name: %define project_name project}

Summary: %{project_name}
Name: %{project_name}
Version: %{project_version}
Release: %{project_release}
License: MIT
Group: Applications/Github
URL: http://github.com

Source0: %{name}-%{version}-%{release}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires: gcc
Requires(post): /sbin/chkconfig /usr/sbin/useradd
Requires(preun): /sbin/chkconfig, /sbin/service
Requires(postun): /sbin/service
Provides: rts

Packager: Seth Call <sethcall@gmail.com>

%description
%{project_name}

%prep
%setup

%build

%install
%{__rm} -rf %{buildroot}

%{__install} -v -Dp -m 0750 src/my_code %{buildroot}/opt/%{project_name}/my_code

%pre

%preun

%post

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
/opt/%{project_name}/my_code

%changelog
* Sat Oct 10 2011 - I did the work
- Yup.
