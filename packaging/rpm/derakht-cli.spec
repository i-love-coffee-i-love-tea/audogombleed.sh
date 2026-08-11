Name:           derakht-cli
Version:        2.0.0
Release:        1%{?dist}
Summary:        Create CLIs with auto-completable command trees

License:        BSD-2-Clause
URL:            https://github.com/i-love-coffee-i-love-tea/derakht-cli
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash >= 4.2
Requires:       gawk

%description
Derakht generates shell CLIs from a plain text config file.
Define commands and arguments declaratively — tab completion,
command abbreviation, help output, and execution all come for free.

Works in both bash and zsh. No dependencies beyond awk and the shell.

%prep
%autosetup -n derakht-cli-%{version}

%build
# Nothing to build — shell script

%install
install -Dpm 755 derakht.sh %{buildroot}%{_bindir}/derakht
install -Dpm 644 derakht.1 %{buildroot}%{_mandir}/man1/derakht.1
install -Dpm 644 LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE

%files
%license LICENSE
%{_bindir}/derakht
%{_mandir}/man1/derakht.1*

%changelog
* Sun Aug 09 2026 Steffen Kremsler <github.com@gobuki.org> - 2.0.0-1
- Initial RPM package
