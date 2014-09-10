

http://projects.theforeman.org/issues/5637


0. KNOWN BUGS
---------------------------------------------------------------------------------------------
	1.  "Verwaltung -> Einstellungen -> Puppet" -> puppetrun steht auf false und muss auf true gesetzt werden


1. UBUNTU SERVER INSTALLATION VON BOOT STICK (14.04)
---------------------------------------------------------------------------------------------
	1.  Installatons-Sprache: Englisch
	2.  Im Haupt-Men�: "Install Ubuntu Server"
	3.  Language "German" + "Forsetzen?" best�tigen
	4.  Land oder Gebiet "Deutschland"
	5.  Tastaturmodell erkennen - JA
	6.  Tasten dr�cken, � best�tigen und dr�cken, � verneinen, best�tigen
	
	7.  Prim�re Netzwerk-Schnittstelle: eth1
	8.  Rechnername: server.local.cloud
	
	9.  Land des Spiegelservers: Deutschland (de.archive.ubuntu.com)
	10. Proxy leer lassen
	
	11. Vollst�ndiger Benutzername: server
	12. Benutzername f�r Konto: server
	13. Passwort: "server" + Schwaches Passwort verwenden - JA
	14. Pers�nliche Ordner verschl�sseln - NEIN
	
	15. Zeitzone best�tigen (Europe/Berlin)
	
	16. Partitionierungsmethode: "Gef�hrt - vollst�ndige Festplatte verwenden"
	17. Festplatte ausw�hlen: SCSI1 (320GB)
	18. �nderungen auf die Festplatte schreiben? - JA
	
	19. Automatische Aktualisierung? - NEIN
	20. Welche Software soll installiert werden? - [X] OpenSSH Server
	21. GRUB-Loader in den MBR installieren? - JA
	22. Uhrzeit auf UTC? - JA
	23. USB-Stick entfernen und rebooten
	

2. POST-INSTALLATION
---------------------------------------------------------------------------------------------
	1.  wget https://raw.github.com/codecentric/foreman-poc/bare_metal/files/System/post-install.sh
	3.  chmod +x post-install.sh
	4.  ./post-install.sh
	

3. INSTALLATION VIA PUPPET
---------------------------------------------------------------------------------------------
	1.  cd git/foreman-poc/files/System
	2.  chmod +x run-puppet.sh
	3.  ./run-puppet.sh



4. POST INSTALL in FOREMAN
---------------------------------------------------------------------------------------------
	1.  Unter "Hosts -> Bereitstellungsvorlagen" den Button "PXE-Vorgabe erstellen" klicken
	2.  Unter "Hosts -> Betriebssysteme" beim Ubuntu 12.10 unter "Vorlagen" die 3 Preseed Vorlagen hinzuf�gen
	3.  Unter "Verwaltung -> Einstellungen" -> "Puppet" -> puppetrun von "false" auf "true" setzen
	
4.1 NOTIZEN
---------------------------------------------------------------------------------------------
	1.  Die vorinstallierte Ubuntu 12.10 funktioniert bei mir nicht, der archiv mirror wird nicht gefunden
		Abhilfe: Ein neues OS anlegen (Siehe Punkt 5) z.B. f�r 14.04

	
5. OPTIONAL
---------------------------------------------------------------------------------------------

Neues OS hinzuf�gen:

Bereitstellungsvorlagen: 
	- Preseed default
	- Preseed default finish
	- Preseed default PXELinux
		
		-> "Zusammenschluss" -> alle r�berziehen
Bei Betriebssystem -> "Vorlagen" diese ausw�hlen in allen Feldern  


Puppet Module laden:

Alle Puppet Module kopieren unter /etc/puppet/environments/cloudbox/modules/




