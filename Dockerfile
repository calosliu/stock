# 基础镜像
# https://hub.docker.com/_/python/tags?page=1&name=3.11-slim-bullseye
FROM docker.io/python:3.11-slim-bullseye

MAINTAINER myh
#增加语言utf-8
ENV LANG=zh_CN.UTF-8
ENV LC_CTYPE=zh_CN.UTF-8
ENV LC_ALL=C
ENV PYTHONPATH=/data/InStock

WORKDIR /data
COPY . /data/InStock
COPY cron/cron.* /etc/

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
  echo "Asia/Shanghai" >/etc/timezone

RUN apt-get update >/dev/null && \
  apt-get install -y cron gcc make python3-dev default-libmysqlclient-dev build-essential pkg-config curl >/dev/null && \
  curl -SL https://github.com/TA-Lib/ta-lib/releases/download/v0.6.4/ta-lib-0.6.4-src.tar.gz | tar -xzC . && \
  cd ta-lib-0.6.4/ && ./configure --prefix=/usr >/dev/null && make >/dev/null && make install && \
  cd .. && pip install TA-Lib && rm -rf ta-lib* && \
  pip install supervisor mysqlclient && \
  pip install -r /data/InStock/requirements.txt && \
  apt-get --purge remove -y gcc make python3-dev default-libmysqlclient-dev curl && \
  rm -rf /root/.cache/* && \
  apt-get clean && apt-get autoclean && apt-get autoremove -y

#add cron sesrvice.
#任务调度
RUN chmod 755 /data/InStock/instock/bin/run_*.sh && \
  chmod 755 /etc/cron.*/* && \
  echo "SHELL=/bin/sh \n\
  PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin \n\
  # min hour day month weekday command \n\
  */30 9,10,11,13,14,15 * * 1-5 /bin/run-parts /etc/cron.hourly \n\
  30 17 * * 1-5 /bin/run-parts /etc/cron.workdayly \n\
  30 10 * * 3,6 /bin/run-parts /etc/cron.monthly \n" >/var/spool/cron/crontabs/root && \
  chmod 600 /var/spool/cron/crontabs/root

EXPOSE 9988

ENTRYPOINT ["supervisord","-n","-c","/data/InStock/supervisor/supervisord.conf"]
