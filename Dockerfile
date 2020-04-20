##################################################################
##
## TEMPORARY DOCKER IMAGE TO BUILD DUMP1090
##
##################################################################
FROM multiarch/debian-debootstrap:armhf-buster as dump1090

ENV DUMP1090_VERSION v3.8.1

RUN apt-get update -y && \
	apt-get install -y \
	sudo \
	git-core \
	build-essential \
	debhelper \
	librtlsdr-dev \
	pkg-config \
	dh-systemd \
	libncurses5-dev \
	libbladerf-dev && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone -b ${DUMP1090_VERSION} --depth 1 https://github.com/flightaware/dump1090 && \
	cd dump1090 && \
	make




##################################################################
##
## TEMPORARY DOCKER IMAGE TO BUILD PIAWARE
##
##################################################################
FROM multiarch/debian-debootstrap:armhf-buster as piaware

ENV DEBIAN_VERSION buster
ENV PIAWARE_VERSION v3.8.1

WORKDIR /tmp
RUN apt-get update -y && \
	apt-get install -y \
	sudo \
	git-core \
	wget \
	build-essential \
	debhelper \
	tcl8.6-dev \
	autoconf \
	python3-dev \
	python-virtualenv \
	libz-dev \
	dh-systemd \
	net-tools \
	tclx8.4 \
	tcllib \
	tcl-tls \
	itcl3 \
	python3-venv \
	dh-systemd \
	init-system-helpers \
	libboost-system-dev \
	libboost-program-options-dev \
	libboost-regex-dev \
	libboost-filesystem-dev && \
	rm -rf /var/lib/apt/lists/*

RUN git clone -b ${PIAWARE_VERSION} --depth 1 https://github.com/flightaware/piaware_builder.git piaware_builder
WORKDIR /tmp/piaware_builder
RUN ./sensible-build.sh ${DEBIAN_VERSION} && \
	cd package-${DEBIAN_VERSION} && \
	dpkg-buildpackage -b




##################################################################
##
## TEMPORARY DOCKER IMAGE TO BUILD CONFD
##
##################################################################
FROM multiarch/debian-debootstrap:armhf-buster as confd

ENV CONFD_VERSION v0.16.0

WORKDIR /tmp
RUN apt-get update -y && \
	apt-get install -y \
	sudo \
	git-core \
	build-essential \
  golang && \
	rm -rf /var/lib/apt/lists/*

RUN git clone -b ${CONFD_VERSION} --depth 1 https://github.com/kelseyhightower/confd.git && \
	cd confd && \
  export GOPATH=/tmp/go && \
  go get github.com/BurntSushi/toml && \
  go get github.com/kelseyhightower/confd/backends && \
  go get github.com/kelseyhightower/confd/log && \
  go get github.com/kelseyhightower/confd/resource/template && \
	make




##################################################################
##
## FINAL DOCKER IMAGE TO BE USED
##
##################################################################
FROM multiarch/debian-debootstrap:armhf-buster-slim as serve

ENV DEBIAN_VERSION buster
ENV RTL_SDR_VERSION 0.6.0
ENV FR24FEED_VERSION 1.0.25-1
ENV RBFEEDER_VERSION 0.3.3-20200203195559
ENV S6_OVERLAY_VERSION v1.22.1.0

LABEL maintainer="reiser.thomas@gmail.com"

RUN apt-get update -y && \
	apt-get install -y \
	nano \
	wget \
	# rtl-sdr
	devscripts \
	libusb-1.0-0-dev \
	pkg-config \
	ca-certificates \
	git-core \
	cmake \
	build-essential \
	# piaware
	libboost-system-dev \
	libboost-program-options-dev \
	libboost-regex-dev \
	libboost-filesystem-dev \
	libtcl \
	net-tools \
	tclx \
	tcl \
	tcllib \
	tcl-tls \
	itcl3 \
	librtlsdr-dev \
	pkg-config \
	libncurses5-dev \
	libbladerf-dev \
	# tcl-tls
	libssl-dev \
    tcl-dev \
    chrpath \
	# rbfeeder
	libjansson4 \
	libncurses5 \
	libtinfo5 && \
	rm -rf /var/lib/apt/lists/*

# RTL-SDR
WORKDIR /tmp
RUN mkdir -p /etc/modprobe.d && \
	echo 'blacklist r820t' >> /etc/modprobe.d/raspi-blacklist.conf && \
	echo 'blacklist rtl2832' >> /etc/modprobe.d/raspi-blacklist.conf && \
	echo 'blacklist rtl2830' >> /etc/modprobe.d/raspi-blacklist.conf && \
	echo 'blacklist dvb_usb_rtl28xxu' >> /etc/modprobe.d/raspi-blacklist.conf && \
	git clone -b ${RTL_SDR_VERSION} --depth 1 https://github.com/osmocom/rtl-sdr.git && \
	mkdir rtl-sdr/build && \
	cd rtl-sdr/build && \
	cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
	make && \
	make install && \
	ldconfig && \
	rm -rf /tmp/rtl-sdr

# TCL-TLS
RUN cd /tmp && \
    git clone --depth 1 http://github.com/flightaware/tcltls-rebuild.git && \
    cd tcltls-rebuild && \
    ./prepare-build.sh ${DEBIAN_VERSION} && \
    cd package-${DEBIAN_VERSION} && \
    dpkg-buildpackage -b --no-sign && \
    cd ../ && \
    dpkg -i tcl-tls_*.deb && \
	rm tcl-tls_*.deb

# DUMP1090
RUN mkdir -p /usr/lib/fr24/public_html/data
COPY --from=dump1090 /tmp/dump1090/dump1090 /usr/lib/fr24/
COPY --from=dump1090 /tmp/dump1090/public_html /usr/lib/fr24/public_html
RUN rm /usr/lib/fr24/public_html/config.js

# PIAWARE
COPY --from=piaware /tmp/piaware_builder /tmp/piaware_builder
RUN cd /tmp/piaware_builder && \
	dpkg -i piaware_*_*.deb && \
	rm -rf /tmp/piaware && \
	rm /etc/piaware.conf

# CONFD
COPY --from=confd /tmp/confd/bin/confd /opt/confd/bin/confd

# FR24FEED
WORKDIR /fr24feed
ADD https://repo-feed.flightradar24.com/rpi_binaries/fr24feed_${FR24FEED_VERSION}_armhf.tgz /fr24feed
RUN tar -xzf fr24feed_*_armhf.tgz && \
	mv fr24feed_armhf/* . && \
	rm -r fr24feed_armhf/ && \
	rm fr24feed_*_armhf.tgz

# RBFEEDER
WORKDIR /rbfeeder
RUN wget -U "Debian APT-HTTP/1.3" https://apt.rb24.com/pool/main/r/rbfeeder/rbfeeder_${RBFEEDER_VERSION}_armhf.deb && \
	ar x rbfeeder_*_armhf.deb && \
	rm rbfeeder_*_armhf.deb && \
	rm control.tar* && \
	rm debian-binary && \
	tar -xf data.tar* && \
	rm data.tar* && \
	rm -r lib/ && \
	rm -r etc/ && \
	cp usr/bin/* /rbfeeder && \
	rm -r usr/

# S6 OVERLAY
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-armhf.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-armhf.tar.gz -C / && \
	rm /tmp/s6-overlay-armhf.tar.gz
COPY /root /

# CLEANUP
RUN rm -r /tmp/*

EXPOSE 8754 8080 30001 30002 30003 30004 30005 30104 

ENTRYPOINT ["/init"]