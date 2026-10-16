"""Blacklist 1.1 store texts: SMS scam filter + "Check a message" + official data sources.
Inserts a new section after the first paragraph of each description and sets subtitle, promo, whatsNew."""
import json
import pathlib

P = pathlib.Path(__file__).with_name('metadata.json')
m = json.loads(P.read_text(encoding='utf-8'))

NEW = {
    'en-US': dict(
        subtitle='Block spam calls & scam SMS',
        promo='New: SMS scam filter for iPhone and "Check a message" — paste any suspicious text and see the warning signs. Everything is checked on your phone.',
        section='SCAM MESSAGES\n• SMS scam filter: scam texts from unknown senders go straight to Junk in Messages — reported numbers and typical scam signs (fake courier, bank, codes, shortened links), checked offline on your iPhone\n• Check a message: paste a suspicious SMS, WhatsApp or email and see why it is (or isn\'t) a scam, in 16 languages\n• Your own words to block\n\nOFFICIAL DATA\nBesides community reports, the lists include public data: U.S. FTC Do Not Call complaints and the German Federal Network Agency (Bundesnetzagentur) enforcement list.',
        whatsNew='• New Messages tab: SMS scam filter (Settings › Apps › Messages › Unknown & Spam › SMS Filtering › Blacklist)\n• Check a message: paste a suspicious text and see the warning signs\n• Your own words to block\n• Everything runs offline on your phone',
    ),
    'it': dict(
        subtitle='Blocca chiamate e SMS truffa',
        promo='Novità: filtro SMS truffa per iPhone e "Controlla un messaggio": incolla un testo sospetto e scopri i segnali d’allarme. Tutto viene controllato sul telefono.',
        section='MESSAGGI TRUFFA\n• Filtro SMS truffa: gli SMS truffa di mittenti sconosciuti finiscono direttamente negli indesiderati di Messaggi — numeri segnalati e segnali tipici (finto corriere, banca, codici, link accorciati), controllati offline sul tuo iPhone\n• Controlla un messaggio: incolla un SMS, un messaggio WhatsApp o una email sospetta e scopri perché è (o non è) una truffa, in 16 lingue\n• Le tue parole da bloccare\n\nDATI UFFICIALI\nOltre alle segnalazioni della community, le liste includono dati pubblici: i reclami della FTC statunitense (Do Not Call) e l’elenco dei provvedimenti della Bundesnetzagentur tedesca.',
        whatsNew='• Nuova scheda Messaggi: filtro SMS truffa (Impostazioni › App › Messaggi › Sconosciuti e spam › Filtro SMS › Blacklist)\n• Controlla un messaggio: incolla un testo sospetto e vedi i segnali d’allarme\n• Le tue parole da bloccare\n• Tutto funziona offline sul telefono',
    ),
    'fr-FR': dict(
        subtitle='Bloquez appels et SMS arnaques',
        promo='Nouveau : filtre SMS anti-arnaque pour iPhone et « Vérifier un message » — collez un texte suspect et voyez les signaux d’alerte. Tout est vérifié sur votre téléphone.',
        section='MESSAGES FRAUDULEUX\n• Filtre SMS anti-arnaque : les SMS frauduleux d’expéditeurs inconnus vont directement dans les indésirables de Messages — numéros signalés et signes typiques (faux livreur, banque, codes, liens raccourcis), vérifiés hors ligne sur votre iPhone\n• Vérifier un message : collez un SMS, un message WhatsApp ou un e-mail suspect et découvrez pourquoi c’est (ou non) une arnaque, en 16 langues\n• Vos propres mots à bloquer\n\nDONNÉES OFFICIELLES\nEn plus des signalements de la communauté, les listes incluent des données publiques : les plaintes Do Not Call de la FTC américaine et la liste des sanctions de l’agence fédérale allemande (Bundesnetzagentur).',
        whatsNew='• Nouvel onglet Messages : filtre SMS anti-arnaque (Réglages › Apps › Messages › Inconnus et spam › Filtrage SMS › Blacklist)\n• Vérifier un message : collez un texte suspect et voyez les signaux d’alerte\n• Vos propres mots à bloquer\n• Tout fonctionne hors ligne sur votre téléphone',
    ),
    'de-DE': dict(
        subtitle='Spam-Anrufe & Betrugs-SMS stop',
        promo='Neu: SMS-Betrugsfilter fürs iPhone und „Nachricht prüfen“ – verdächtigen Text einfügen und Warnzeichen sehen. Alles wird auf deinem Telefon geprüft.',
        section='BETRUGSNACHRICHTEN\n• SMS-Betrugsfilter: Betrugs-SMS von unbekannten Absendern landen direkt im Junk der Nachrichten-App – gemeldete Nummern und typische Merkmale (falscher Paketdienst, Bank, Codes, Kurzlinks), offline auf deinem iPhone geprüft\n• Nachricht prüfen: verdächtige SMS, WhatsApp-Nachricht oder E-Mail einfügen und sehen, warum es (k)ein Betrug ist – in 16 Sprachen\n• Eigene Wörter blockieren\n\nOFFIZIELLE DATEN\nNeben Community-Meldungen enthalten die Listen öffentliche Daten: die Maßnahmenliste der Bundesnetzagentur und Do-Not-Call-Beschwerden der US-Handelsbehörde FTC.',
        whatsNew='• Neuer Tab Nachrichten: SMS-Betrugsfilter (Einstellungen › Apps › Nachrichten › Unbekannt & Spam › SMS-Filter › Blacklist)\n• Nachricht prüfen: verdächtigen Text einfügen und Warnzeichen sehen\n• Eigene Wörter blockieren\n• Alles läuft offline auf deinem Telefon',
    ),
    'es-ES': dict(
        subtitle='Bloquea llamadas y SMS estafa',
        promo='Novedad: filtro de SMS fraudulentos para iPhone y «Comprobar un mensaje»: pega un texto sospechoso y mira las señales de alarma. Todo se comprueba en tu teléfono.',
        section='MENSAJES FRAUDULENTOS\n• Filtro de SMS fraudulentos: los SMS estafa de remitentes desconocidos van directamente a No deseados en Mensajes — números denunciados y señales típicas (falsa mensajería, banco, códigos, enlaces acortados), comprobados sin conexión en tu iPhone\n• Comprobar un mensaje: pega un SMS, un WhatsApp o un email sospechoso y descubre por qué es (o no) una estafa, en 16 idiomas\n• Tus propias palabras para bloquear\n\nDATOS OFICIALES\nAdemás de las denuncias de la comunidad, las listas incluyen datos públicos: las quejas Do Not Call de la FTC de EE. UU. y la lista de sanciones de la agencia federal alemana (Bundesnetzagentur).',
        whatsNew='• Nueva pestaña Mensajes: filtro de SMS fraudulentos (Ajustes › Apps › Mensajes › Desconocidos y spam › Filtro de SMS › Blacklist)\n• Comprobar un mensaje: pega un texto sospechoso y mira las señales de alarma\n• Tus propias palabras para bloquear\n• Todo funciona sin conexión en tu teléfono',
    ),
    'pt-PT': dict(
        subtitle='Bloqueie chamadas e SMS burla',
        promo='Novo: filtro de SMS fraudulentos para iPhone e «Verificar uma mensagem» — cole um texto suspeito e veja os sinais de alerta. Tudo é verificado no seu telefone.',
        section='MENSAGENS FRAUDULENTAS\n• Filtro de SMS fraudulentos: as SMS de burla de remetentes desconhecidos vão diretamente para o Lixo nas Mensagens — números denunciados e sinais típicos (falsa transportadora, banco, códigos, links encurtados), verificados offline no seu iPhone\n• Verificar uma mensagem: cole um SMS, WhatsApp ou email suspeito e veja porque é (ou não) uma burla, em 16 idiomas\n• As suas próprias palavras a bloquear\n\nDADOS OFICIAIS\nAlém das denúncias da comunidade, as listas incluem dados públicos: as queixas Do Not Call da FTC dos EUA e a lista de sanções da agência federal alemã (Bundesnetzagentur).',
        whatsNew='• Novo separador Mensagens: filtro de SMS fraudulentos (Definições › Apps › Mensagens › Desconhecidos e spam › Filtragem de SMS › Blacklist)\n• Verificar uma mensagem: cole um texto suspeito e veja os sinais de alerta\n• As suas próprias palavras a bloquear\n• Tudo funciona offline no seu telefone',
    ),
    'nl-NL': dict(
        subtitle='Stop spam- en oplichtings-sms',
        promo='Nieuw: sms-oplichtingsfilter voor iPhone en "Bericht controleren" — plak een verdachte tekst en zie de waarschuwingssignalen. Alles wordt op je telefoon gecontroleerd.',
        section='OPLICHTINGSBERICHTEN\n• Sms-oplichtingsfilter: oplichtings-sms’jes van onbekende afzenders gaan direct naar Ongewenst in Berichten — gemelde nummers en typische signalen (nep-pakketdienst, bank, codes, verkorte links), offline gecontroleerd op je iPhone\n• Bericht controleren: plak een verdachte sms, WhatsApp of e-mail en zie waarom het (geen) oplichting is, in 16 talen\n• Je eigen woorden om te blokkeren\n\nOFFICIËLE GEGEVENS\nNaast meldingen van de community bevatten de lijsten openbare gegevens: Do Not Call-klachten van de Amerikaanse FTC en de handhavingslijst van de Duitse Bundesnetzagentur.',
        whatsNew='• Nieuw tabblad Berichten: sms-oplichtingsfilter (Instellingen › Apps › Berichten › Onbekend en spam › Sms-filter › Blacklist)\n• Bericht controleren: plak een verdachte tekst en zie de waarschuwingssignalen\n• Je eigen woorden om te blokkeren\n• Alles werkt offline op je telefoon',
    ),
    'pl': dict(
        subtitle='Blokuj spam i SMS-y oszustów',
        promo='Nowość: filtr SMS-ów oszustów na iPhone’a i „Sprawdź wiadomość” — wklej podejrzany tekst i zobacz sygnały ostrzegawcze. Wszystko sprawdzane w telefonie.',
        section='WIADOMOŚCI OSZUSTÓW\n• Filtr SMS-ów oszustów: SMS-y oszustów od nieznanych nadawców trafiają prosto do Śmieci w Wiadomościach — zgłoszone numery i typowe oznaki (fałszywy kurier, bank, kody, skrócone linki), sprawdzane offline na twoim iPhonie\n• Sprawdź wiadomość: wklej podejrzany SMS, wiadomość z WhatsAppa lub e-mail i zobacz, dlaczego to (nie) jest oszustwo, w 16 językach\n• Własne słowa do blokowania\n\nOFICJALNE DANE\nOprócz zgłoszeń społeczności listy zawierają dane publiczne: skargi Do Not Call amerykańskiej FTC i listę sankcji niemieckiej agencji Bundesnetzagentur.',
        whatsNew='• Nowa karta Wiadomości: filtr SMS-ów oszustów (Ustawienia › Aplikacje › Wiadomości › Nieznani i spam › Filtrowanie SMS › Blacklist)\n• Sprawdź wiadomość: wklej podejrzany tekst i zobacz sygnały ostrzegawcze\n• Własne słowa do blokowania\n• Wszystko działa offline w telefonie',
    ),
    'ro': dict(
        subtitle='Blochează apeluri și SMS-uri',
        promo='Nou: filtru SMS anti-înșelătorie pentru iPhone și „Verifică un mesaj” — lipește un text suspect și vezi semnalele de alarmă. Totul se verifică pe telefon.',
        section='MESAJE FRAUDULOASE\n• Filtru SMS anti-înșelătorie: SMS-urile frauduloase de la expeditori necunoscuți ajung direct la Nedorite în Mesaje — numere semnalate și semne tipice (curier fals, bancă, coduri, linkuri scurtate), verificate offline pe iPhone\n• Verifică un mesaj: lipește un SMS, un mesaj WhatsApp sau un e-mail suspect și vezi de ce este (sau nu) o înșelătorie, în 16 limbi\n• Propriile cuvinte de blocat\n\nDATE OFICIALE\nPe lângă semnalările comunității, listele includ date publice: plângerile Do Not Call ale FTC din SUA și lista sancțiunilor agenției federale germane (Bundesnetzagentur).',
        whatsNew='• Filă nouă Mesaje: filtru SMS anti-înșelătorie (Configurări › Aplicații › Mesaje › Necunoscuți și spam › Filtrare SMS › Blacklist)\n• Verifică un mesaj: lipește un text suspect și vezi semnalele de alarmă\n• Propriile cuvinte de blocat\n• Totul funcționează offline pe telefon',
    ),
    'sv': dict(
        subtitle='Stoppa spam och bedrägeri-sms',
        promo='Nyhet: sms-bedrägerifilter för iPhone och "Kontrollera ett meddelande" — klistra in en misstänkt text och se varningstecknen. Allt kontrolleras i telefonen.',
        section='BEDRÄGERIMEDDELANDEN\n• Sms-bedrägerifilter: bedrägeri-sms från okända avsändare hamnar direkt i Skräp i Meddelanden — rapporterade nummer och typiska tecken (falskt fraktbolag, bank, koder, förkortade länkar), kontrollerade offline på din iPhone\n• Kontrollera ett meddelande: klistra in ett misstänkt sms, WhatsApp-meddelande eller mejl och se varför det är (eller inte är) bedrägeri, på 16 språk\n• Egna ord att blockera\n\nOFFICIELLA DATA\nFörutom communityns rapporter innehåller listorna offentliga data: Do Not Call-klagomål från amerikanska FTC och den tyska myndigheten Bundesnetzagenturs åtgärdslista.',
        whatsNew='• Ny flik Meddelanden: sms-bedrägerifilter (Inställningar › Appar › Meddelanden › Okända och skräp › Sms-filtrering › Blacklist)\n• Kontrollera ett meddelande: klistra in en misstänkt text och se varningstecknen\n• Egna ord att blockera\n• Allt fungerar offline i telefonen',
    ),
    'ru': dict(
        subtitle='Блок спам-звонков и СМС-афер',
        promo='Новое: фильтр мошеннических СМС для iPhone и «Проверить сообщение» — вставьте подозрительный текст и увидите тревожные признаки. Всё проверяется на телефоне.',
        section='МОШЕННИЧЕСКИЕ СООБЩЕНИЯ\n• Фильтр мошеннических СМС: такие СМС от неизвестных отправителей сразу попадают в «Спам» в Сообщениях — номера из жалоб и типичные признаки (фальшивая доставка, банк, коды, короткие ссылки), проверка офлайн на вашем iPhone\n• Проверить сообщение: вставьте подозрительное СМС, сообщение WhatsApp или письмо и узнайте, почему это (не) мошенничество, на 16 языках\n• Свои слова для блокировки\n\nОФИЦИАЛЬНЫЕ ДАННЫЕ\nКроме жалоб сообщества, списки включают открытые данные: жалобы Do Not Call американской FTC и список санкций немецкого агентства Bundesnetzagentur.',
        whatsNew='• Новая вкладка «Сообщения»: фильтр мошеннических СМС (Настройки › Приложения › Сообщения › Неизвестные и спам › Фильтрация SMS › Blacklist)\n• Проверить сообщение: вставьте подозрительный текст и увидите тревожные признаки\n• Свои слова для блокировки\n• Всё работает офлайн на телефоне',
    ),
    'uk': dict(
        subtitle='Блок спам-дзвінків і СМС-афер',
        promo='Нове: фільтр шахрайських СМС для iPhone і «Перевірити повідомлення» — вставте підозрілий текст і побачите тривожні ознаки. Усе перевіряється на телефоні.',
        section='ШАХРАЙСЬКІ ПОВІДОМЛЕННЯ\n• Фільтр шахрайських СМС: такі СМС від невідомих відправників одразу потрапляють у «Небажані» в Повідомленнях — номери зі скарг і типові ознаки (фальшива доставка, банк, коди, короткі посилання), перевірка офлайн на вашому iPhone\n• Перевірити повідомлення: вставте підозріле СМС, повідомлення WhatsApp чи лист і дізнайтеся, чому це (не) шахрайство, 16 мовами\n• Власні слова для блокування\n\nОФІЦІЙНІ ДАНІ\nОкрім скарг спільноти, списки містять відкриті дані: скарги Do Not Call американської FTC і перелік санкцій німецького агентства Bundesnetzagentur.',
        whatsNew='• Нова вкладка «Повідомлення»: фільтр шахрайських СМС (Параметри › Програми › Повідомлення › Невідомі та спам › Фільтрування SMS › Blacklist)\n• Перевірити повідомлення: вставте підозрілий текст і побачите тривожні ознаки\n• Власні слова для блокування\n• Усе працює офлайн на телефоні',
    ),
    'tr': dict(
        subtitle='Spam arama ve sahte SMS engeli',
        promo='Yeni: iPhone için dolandırıcı SMS filtresi ve "Mesaj kontrol et" — şüpheli bir metni yapıştırın, uyarı işaretlerini görün. Her şey telefonunuzda kontrol edilir.',
        section='DOLANDIRICI MESAJLAR\n• Dolandırıcı SMS filtresi: bilinmeyen gönderenlerden gelen dolandırıcı SMS’ler doğrudan Mesajlar’daki Gereksiz’e gider — bildirilen numaralar ve tipik işaretler (sahte kargo, banka, kodlar, kısaltılmış bağlantılar), iPhone’unuzda çevrimdışı kontrol edilir\n• Mesaj kontrol et: şüpheli bir SMS, WhatsApp mesajı veya e-postayı yapıştırın ve neden dolandırıcılık olduğunu (ya da olmadığını) 16 dilde görün\n• Engellenecek kendi kelimeleriniz\n\nRESMİ VERİLER\nTopluluk bildirimlerinin yanı sıra listeler kamuya açık veriler içerir: ABD FTC’nin Do Not Call şikâyetleri ve Alman Bundesnetzagentur’un yaptırım listesi.',
        whatsNew='• Yeni Mesajlar sekmesi: dolandırıcı SMS filtresi (Ayarlar › Uygulamalar › Mesajlar › Bilinmeyen ve Gereksiz › SMS Filtreleme › Blacklist)\n• Mesaj kontrol et: şüpheli bir metni yapıştırın ve uyarı işaretlerini görün\n• Engellenecek kendi kelimeleriniz\n• Her şey telefonunuzda çevrimdışı çalışır',
    ),
    'ar-SA': dict(
        subtitle='احظر مكالمات ورسائل الاحتيال',
        promo='جديد: فلتر رسائل الاحتيال لجهاز iPhone و«افحص رسالة» — الصق نصًا مريبًا وشاهد علامات التحذير. يتم الفحص كله على هاتفك.',
        section='رسائل الاحتيال\n• فلتر رسائل الاحتيال: رسائل الاحتيال من المرسلين غير المعروفين تذهب مباشرة إلى غير المرغوب في تطبيق الرسائل — أرقام مُبلغ عنها وعلامات معتادة (شركة شحن مزيفة، بنك، رموز، روابط مختصرة)، تُفحص دون اتصال على iPhone\n• افحص رسالة: الصق رسالة SMS أو واتساب أو بريدًا إلكترونيًا مريبًا واعرف لماذا هي احتيال (أو لا)، بـ16 لغة\n• كلماتك الخاصة للحظر\n\nبيانات رسمية\nإلى جانب بلاغات المجتمع، تتضمن القوائم بيانات عامة: شكاوى Do Not Call لدى لجنة التجارة الفيدرالية الأمريكية وقائمة عقوبات الوكالة الاتحادية الألمانية Bundesnetzagentur.',
        whatsNew='• تبويب جديد للرسائل: فلتر رسائل الاحتيال (الإعدادات › التطبيقات › الرسائل › غير المعروف والبريد العشوائي › تصفية الرسائل › Blacklist)\n• افحص رسالة: الصق نصًا مريبًا وشاهد علامات التحذير\n• كلماتك الخاصة للحظر\n• كل شيء يعمل دون اتصال على هاتفك',
    ),
    'zh-Hans': dict(
        subtitle='拦截骚扰电话和诈骗短信',
        promo='新功能：iPhone 诈骗短信过滤和“检查一条消息”——粘贴可疑文字即可看到警示信号。所有检查都在手机上完成。',
        section='诈骗短信\n• 诈骗短信过滤：陌生号码发来的诈骗短信直接进入“信息”的垃圾信息——包括被举报的号码和典型诈骗特征（假冒快递、银行、验证码、短链接），在 iPhone 上离线检查\n• 检查一条消息：粘贴可疑的短信、WhatsApp 消息或邮件，用 16 种语言告诉你为什么是（或不是）诈骗\n• 自定义屏蔽词\n\n官方数据\n除社区举报外，名单还包含公开数据：美国联邦贸易委员会（FTC）的 Do Not Call 投诉和德国联邦网络局（Bundesnetzagentur）的处罚名单。',
        whatsNew='• 新增“短信”页：诈骗短信过滤（设置 › App › 信息 › 未知与垃圾信息 › 短信过滤 › Blacklist）\n• 检查一条消息：粘贴可疑文字查看警示信号\n• 自定义屏蔽词\n• 全部在手机上离线运行',
    ),
    'ja': dict(
        subtitle='迷惑電話と詐欺SMSをブロック',
        promo='新機能：iPhone向け詐欺SMSフィルタと「メッセージをチェック」。怪しい文面を貼り付けると警告サインがわかります。チェックはすべて端末内で行われます。',
        section='詐欺メッセージ\n• 詐欺SMSフィルタ：知らない送信者からの詐欺SMSを「メッセージ」の迷惑メッセージへ自動で振り分け。報告された番号と典型的な詐欺の特徴（偽の宅配業者、銀行、コード、短縮URL）をiPhone内でオフライン判定\n• メッセージをチェック：怪しいSMS、WhatsApp、メールを貼り付けると、詐欺かどうかとその理由を16言語で表示\n• ブロックする言葉を自分で追加\n\n公的データ\nコミュニティの報告に加え、米国連邦取引委員会（FTC）のDo Not Call苦情データやドイツ連邦ネットワーク庁（Bundesnetzagentur）の処分リストなどの公開データも含まれます。',
        whatsNew='• 新しい「メッセージ」タブ：詐欺SMSフィルタ（設定 › アプリ › メッセージ › 不明な差出人と迷惑メッセージ › SMSフィルタ › Blacklist）\n• メッセージをチェック：怪しい文面を貼り付けて警告サインを確認\n• ブロックする言葉を自分で追加\n• すべて端末内でオフライン動作',
    ),
}

for loc, new in NEW.items():
    d = m[loc]
    assert len(new['subtitle']) <= 30, (loc, len(new['subtitle']))
    assert len(new['promo']) <= 170, (loc, len(new['promo']))
    desc = d['description']
    marker = new['section'].split('\n', 1)[0]
    if marker not in desc:
        head, rest = desc.split('\n\n', 1)
        desc = head + '\n\n' + new['section'] + '\n\n' + rest
    assert len(desc) <= 4000, (loc, len(desc))
    d.update(subtitle=new['subtitle'], promo=new['promo'], description=desc, whatsNew=new['whatsNew'])
P.write_text(json.dumps(m, ensure_ascii=False, indent=2), encoding='utf-8')
print('updated', len(NEW))
