Name:           derakht-cli-fish
Version:        2.0.0
Release:        1%{?dist}
Summary:        Fish shell support for derakht-cli

License:        BSD-2-Clause
URL:            https://github.com/i-love-coffee-i-love-tea/derakht-cli
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/derakht-cli-%{version}.tar.gz

BuildArch:      noarch
Requires:       fish
Requires:       gawk

%description
Derakht generates shell CLIs from a plain text config file.
Define commands and arguments declaratively — tab completion,
command abbreviation, help output, and execution all come for free.

This package provides the fish shell implementation.
Install derakht-cli for the bash/zsh version.

%prep
%autosetup -n derakht-cli-%{version}

%build
# Nothing to build — shell script

%install
install -Dpm 644 derakht.fish %{buildroot}%{_bindir}/derakht-fish
install -Dpm 644 derakht.1 %{buildroot}%{_mandir}/man1/derakht.1

%files
%license LICENSE
%{_bindir}/derakht-fish
%{_mandir}/man1/derakht.1*

%changelog
* Sun Aug 09 2026 Steffen Kremsler <github.com@gobuki.org> - 2.0.0-1
- Initial fish package
