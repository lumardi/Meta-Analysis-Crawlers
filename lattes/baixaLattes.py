#!/usr/bin/python
# encoding: utf-8

import argparse
import bs4
import logging
import time
import os
import urlparse

from fake_useragent import UserAgent
from selenium import webdriver
from selenium.common.exceptions import InvalidArgumentException, TimeoutException

import warnings
warnings.filterwarnings("ignore")

RESULTS_DIR = os.environ.get('DATA_DIR', 'htmls')
URL = 'http://buscatextual.cnpq.br/buscatextual/preview.do?metodo=apresentar&id={0}'
URL_LATTES_ID10 = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id={0}'
URL_LATTES_ID16 = 'http://lattes.cnpq.br/{0}'
URL_DOWNLOAD_XML = "http://buscatextual.cnpq.br/buscatextual/download.do?metodo=apresentar&idcnpq={0}"


class LattesRobot:
    def __init__(self, driver_path, results_dir):
        self.driver_path = driver_path
        self.results_dir = results_dir
        self.driver = None
        self.ua = UserAgent()
        self.identifiers = set()
        self.downloaded_identifiers = set()
        self.sleep_time = 5
        self.lid_type = -1
        self.initialize()

    def initialize(self):
        if not os.path.exists(self.driver_path):
            logging.error('Invalid driver path: %s' % self.driver_path)
            exit(1)

        if not os.path.exists(self.results_dir):
            os.makedirs(self.results_dir)

    def load_codes(self, id_lattes):
        self.identifiers.add(id_lattes)
        self._set_lid_type()

    def check_downloaded_cvs(self):
        self.downloaded_identifiers = {h for h in os.listdir(self.results_dir) if len(h) == self.lid_type}

    def create_driver(self):
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("start-maximized")
        chrome_options.add_argument("headless")
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        chrome_options.add_experimental_option('prefs', {'download.default_directory': self.results_dir})

        self.driver = webdriver.Chrome(options=chrome_options, executable_path=self.driver_path)
        self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        self.driver.execute_cdp_cmd('Network.setUserAgentOverride', {"userAgent": self.ua.chrome})

    def rotate_user_agent(self):
        self.driver.execute_cdp_cmd('Network.setUserAgentOverride', {"userAgent": self.ua.chrome})

    def open_lattes_website(self):
        self.driver.get(URL)
        time.sleep(self.sleep_time)

    def collect_html_cvs(self, start, end):
        total_lids = len(list(self.identifiers)[start:end])

        for identifier in sorted(self.identifiers)[start:end]:
            lids = self._get_lids_10_16(identifier)

            if lids[10]:
                if lids[self.lid_type] not in self.downloaded_identifiers:
                    self._execute_js(lids)


    def store_html(self, lid, page):
        with open(os.path.join(self.results_dir, lid), 'w') as fout:
            try:
                data = page.encode('iso-8859-1', 'replace').strip()
            except UnicodeEncodeError:
                data = page #.encode('utf-8').strip()

            if data:
                fout.write(data)

    def _execute_js(self, lids):
        self.rotate_user_agent()
        self.open_lattes_website()

        cmd_set_url = "url=" + "\"" + URL_LATTES_ID10.format(lids[10]) + "\""

        self.driver.execute_script(cmd_set_url)
        time.sleep(self.sleep_time / 10)

        cmd_request = """
            urls = []
            grecaptcha.execute('6Le8-aQUAAAAAEh7lq-D8bscahYZDZ4RKXBEhiov', { action: 'id_form_previw' }).then(function (token) {
                $('#id_form_previw').prepend('<input type="hidden" name="g-recaptcha-response" value="' + token + '">');
                $("#token-captchar").val(token);
                url_with_token = url + "&tokenCaptchar=" + token
                urls.push(url_with_token)
            });"""

        self.driver.execute_script(cmd_request)
        time.sleep(self.sleep_time / 2)

        cmd_finish = """return urls[0]"""

        try:
            self.driver.get(self.driver.execute_script(cmd_finish))
            time.sleep(self.sleep_time / 2)

            if not lids[16]:
                lids[16] = self._extract_lid16(self.driver.page_source)

                if self.lid_type == 16 and len(lids[16]) != 16:
                    logging.error('It was not possible to obtain Lattes identifier with 16 chars for %s' % str(lids))
                    return

            self.store_html(lids[self.lid_type], self.driver.page_source)

        except InvalidArgumentException:
            logging.warning('Invalid argument exception: %s failed' % lids[10])

        except TimeoutException:
            logging.warning('Timeout exception: %s failed' % lids[10])

    def _get_lids_10_16(self, lid):
        lids = {10: '', 16: ''}

        if len(lid) == 10:
            lids[10] = lid

        if len(lid) == 16:
            lids[16] = lid

            self.driver.get(URL_LATTES_ID16.format(lid))
            lid10 = urlparse.parse_qs(urlparse.urlparse(self.driver.current_url.encode()).query)['id'][0]

            if len(lid10) == 10:
                lids[10] = lid10

        return lids

    def _extract_lid16(self, page_source):
        soup = bs4.BeautifulSoup(page_source, 'html.parser')
        lid16 = soup.find('span', attrs={'style': 'font-weight: bold; color: #326C99;'}).text.encode()

        if len(lid16) == 16 and lid16.isdigit():
            return lid16

    def _set_lid_type(self):
        if len(self.identifiers) > 0:
            ld = len(list(self.identifiers)[0])
            self.lid_type = ld


def __get_data(id_lattes, diretorio):
    rob = LattesRobot(driver_path="./chromedriver", results_dir=diretorio)
    rob.load_codes(id_lattes)
    rob.check_downloaded_cvs()
    rob.create_driver()

    try:
        #logging.info('Collecting cvs (there are %d cvs to be collected)...' % len(rob.identifiers))
        rob.collect_html_cvs(0, None)
    except KeyboardInterrupt:
        logging.info('Execution was interrupted')
    finally:
        rob.driver.quit()




def baixaCVLattes(id_lattes, diretorio ):
	__get_data(id_lattes, diretorio)
	#raise Exception("Nao foi possivel baixar o CV Lattes em 5 tentativas")
