# -*- encoding : utf-8 -*-


#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding countries..."
puts "\n" * 3

countries = ["Brazil", "Mexico", "Nicaragua"]

puts "-" * 80
puts "[!] Seeding cities..."
puts "\n" * 3

cities = [
  { :name => "Rio de Janeiro", :state => "Rio de Janeiro", :state_code => "RJ", :country_name => "Brazil" },

  { :name => "Tepalcingo", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" },
  { :name => "Cuernavaca", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" },

  { :name => "Managua", :state => "Managua", :state_code => "MN", :country_name => "Nicaragua" }
]
cities.each do |c_hash|
  c = City.find_by_name( c_hash[:name] )
  if c.nil?
    c = City.new
    c.name = c_hash[:name]
    c.state = c_hash[:state]
    c.state_code = c_hash[:state_code]
    c.country = c_hash[:country_name]
    c.time_zone  = "Mexico City"
    c.save!
  end
end


puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

communities = [
  {:name => "Maré",         :city_name => "Rio de Janeiro", :lat => -22.857432, :long => -43.242963},

  {:name => "Tepalcingo",   :city_name => "Tepalcingo", :lat => 18.5957189, :long => -98.8460549 },
  {:name => "Ocachicualli", :city_name => "Cuernavaca", :lat => 18.924799, :long => -99.221359   },

  {:name => "Francisco Meza", :city_name => "Managua", :lat => 12.138632, :long => -86.260808 },
  {:name => "Hialeah",        :city_name => "Managua", :lat => 12.119987, :long => -86.278676 },
  {:name => "Ariel Darce",    :city_name => "Managua", :lat => 12.118762, :long => -86.237639 }
]
communities.each do |c_hash|
  n = Neighborhood.find_by_name( c_hash[:name] )
  if n.nil?
    n                   = Neighborhood.new
    n.name              = c_hash[:name]
    n.latitude          = c_hash[:lat]
    n.longitude         = c_hash[:long]
    n.city_id           = City.find_by_name( c_hash[:city_name] ).id
    n.save!
  end
end


puts "\n" * 3
puts "[ok] Done seeding countries, cities, and neighborhoods..."
puts "-" * 80

#------------------------------------------------------------------------------
# Elimination types, methods, and documentation section.



def seed_manual
  puts "\n" * 3
  puts "[!] Seeding /howto documentation"
  puts "-" * 80

  ds = DocumentationSection.find_by_title("Como se cadastrar")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 1
    ds.title    = "Como se cadastrar"
    ds.content  = "Fazer o seu cadastro no Dengue Torpedo (DT) é fácil!
    Na página inicial insira todas as informações nos campos solicitados.
    Email;
    Nome;
    Nome do meio (quando houver):
    Sobrenome;
    Número de celular, no formato 021XXXXXXXXX (Atenção: insira o 9° dígito);
    Senha para acessar sua conta, mínimo 4 caracteres;
    E Confirmação da senha.

    Para prosseguir clique no botão Cadastre-se, você será direcionado para a página de Configurações, nela você completa o seu cadastro incluindo mais informações pessoais.

    ATENÇÃO: Você deve escrever o seu nome como consta em um documento válido, como RG, esse dado será utilizado na troca dos seus pontos por prêmios!

    Apenas moradores da Maré convidados por um usuário ou membro da equipe Dengue Torpedo podem participar! Atualmente estamos na fase inicial aperfeiçoando o aplicativo com os moradores da Maré. Em nossa próxima fase, o Dengue Torpedo será aberto a moradores de outros bairros da cidade. "

    ds.save(:validate => false)
  end

  ds = DocumentationSection.find_by_title("Como completar sua conta")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 2
    ds.title    = "Como completar sua conta"
    ds.content  = "Para completar a sua conta você precisa fornecer mais alguns dados pessoais.
     Assim que você apertar o botão Cadastre-se na página principal, você será direcionado para a página de Configurações.
     Nela os dados que você inseriu na página principal já estarão preenchidos. Você só precisa inserir os outros dados que ajudarão a personalizar a sua conta, deixando ela com a sua cara!  Os campos estão divididos em dois grupos: Configurações de morador e Configurações da casa.


     Configurações de morador
     ---------------------
     Para completar as configurações de morador, basta preencher os campos em branco.

     * Inclua o seu Apelido se tiver;
     * Clique no botão do gênero masculino ou feminino;
     * Digite a sua Operadora de celular e Confirme no campo abaixo;
     * Selecione o tipo de conta de celular pré-pago ou pós-pago;
     * Insira uma imagem pessoal para o seu perfil, se quiser.


     Configurações da casa
     ---------------------
     Você deve completar os dados da Configuração da Casa também no primeiro acesso. Para configurar a sua casa, basta preencher os campos de:

     * Rua, beco, viela, etc;
     * Nome;
     * Número;
     * Imagem da residência.

     Após preencher os campos do endereço, um marcador irá aparecer no mapa ao lado. Você deve verificar se o marcador está na localização correta da sua casa. Caso ele não esteja, basta você ir até onde sua casa fica e clicar sobre a localização correta. O marcador irá aparecer.

     ATENÇÃO: Caso algum morador da sua casa já tenha se cadastrado no DT é necessário que você se cadastre como morador dessa casa inserindo o mesmo endereço e nome da casa. Ex: Se o seu irmão cadastrou a casa da sua família como Souza, você também deverá se cadastrar nela inserindo o mesmo endereço e Nome da casa como Souza.

     Se você se cadastrou no site porque um amigo ou vizinho convidou você, não se esqueça de indicar o nome dele no campo Alguém o convidou a se cadastrar no DT?. Nesse campo selecione se a pessoa que o convidou é um morador/vizinho ou um ACS/AVS e digite o nome dele no campo abaixo.
    "
    ds.save(:validate => false)
  end


  ds = DocumentationSection.find_by_title("Barra de navegação")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 3
    ds.title    = "Barra de navegação"
    ds.content  = "Na barra de navegação você encontra os links para acessar cada página do site:

       * Meu Perfil;
       * Minha Casa;
       * Minha Comunidade;
       * Focos Marcados;
       * Configurações.

       A barra de navegação pode ser acessada a qualquer momento, ela aparece em todas as páginas enquanto você estiver logado.

       Após realizar o seu cadastro, entre na sua conta na página inicial inserindo o seu e-mail e senha no canto superior direito. Você estará logado no site Dengue Torpedo e poderá visualizar a sua conta. Clique em Configurações. Nessa página você poderá atualizar sua conta, e verificar as Configurações de usuário e Configurações de Casa.

       Acesse essa página quando quiser inserir ou alterar seus dados pessoais, imagens de perfil e da casa.
    "
    ds.save(:validate => false)
  end


  ds = DocumentationSection.find_by_title("O que é um foco?")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 4
    ds.title    = "O que é um foco?"
    ds.content  = "Um foco é um lugar com água parada, geralmente limpo, onde os mosquitos põem seus ovos.

       Dengue Torpedo reconhece que há dois tipos de focos:
       * Focos ativos -- com pupas ou larvas de mosquito;
       * Focos potenciais -- possíveis criadouros de mosquito.

       Dengue Torpedo não distingue entre ativos e potenciais. Quando encontrado, os dois tipos são chamados focos marcados e ganham a mesma pontuação.
    "
    ds.save(:validate => false)
  end


  ds = DocumentationSection.find_by_title("Como jogar")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 5
    ds.title    = "Como jogar"
    ds.content  = "Há várias formas de jogar. Você pode:

    * Marcar focos;
    * Eliminar focos;
    * Postar no blog;
    * Convocar amigos e vizinhos para jogar;
    * Ganhar pontos;
    * Trocar pontos por prêmios;
    * Participar das atividades promovidas pelo Dengue Torpedo.

    Toda vez que você acessar o site do Dengue Torpedo poderá visualizar os focos marcados. Há dois tipos de focos marcados, os focos em aberto e os focos já eliminados. Os focos em aberto você deve eliminar para ganhar pontos.

   Visualizando focos
   ------------------
    Ao acessar a página 'Focos Marcados', você será apresentado aos relatos dos focos em aberto e eliminados e um mapa com os focos marcados na região da Maré. Cada relato tem endereço, fotos, descrição e tipo de foco com método de eliminação, além de outras informações. Os focos em aberto possuem um contador que mostra o tempo restante para eliminá-los.

    Você pode utilizar a ferramenta de zoom do mapa para visualizar melhor os focos de uma área. A lista de focos é dinâmica com o ajuste do mapa. Para aumentar ou diminuir a escala do mapa clique no símbolo de + para aumentar o zoom e o símbolo de - para diminuir o zoom. A lista de focos muda com a sua ação, aumentando ou diminuindo o número de focos. Você também pode ajustar a lista de focos arrastando o mapa. Para arrastar o mapa, coloque o cursor do mouse sobre o mapa, mantenha o botão direito pressionado e arraste-o.

    A página 'Focos Marcados' tem 3 filtros para visualizar os focos: Todos, Em aberto e Eliminados. Clique neles para escolher os focos marcados a serem visualizados.



   Marcando focos
   --------------
    Você pode marcar focos através do site (www.denguetorpedo.com) ou enviando um torpedo (SMS) do seu celular.


   Pelo site do Dengue Torpedo
   ---------------------------
    Para marcar um foco, você precisa acessar a sua conta e clicar na página “Focos Marcados” na barra de navegação.Você irá visualizar uma lista dos focos marcados em sua região.

    Para marcar um foco clique no botão Marcar um foco. Você será direcionado a uma nova página. Nela você deverá preencher os campos com os dados solicitados na ordem seguinte:

    1. Endereço do foco localizado;
    O endereço deve ser preenchido no formato solicitado para ser identificado pelo mapa.
    2. Ajuste o marcador no mapa;
    O mapa pode não encontrar o seu endereço. Nesse caso, mova o marcador clicando na localização correta.
    3. Descrição da localização.
    Descreva onde o foco está localizado, se na laje, no quintal, na calçada do endereço, entre outras possíveis localizações.
    4. Carregue a imagem do foco encontrado.
    Clique no botão Escolher arquivo e selecione a imagem do foco encontrado.

    Após finalizar essas etapas, clique em Enviar!. Você será direcionado para a página 'Focos Marcados' onde você vai ver o seu relato com todas as informações preenchidas.

    Para concluir a marcação do foco, clique em Selecione o tipo de foco em verde e selecione o tipo de foco que você encontrou. Em seguida, clique no botão Enviar!. Após submeter o seu foco, o contador aparece com 48 horas e inicia a contagem do tempo restante para que o foco seja eliminado. Também nesse momento, você recebe 50 pontos.

    ATENÇÃO: Caso você tenha uma proposta para outro tipo de foco que não está na lista Tipo de foco, selecione Outro tipo de foco. Você será direcionado para a página “Contato DT”. Nela, descreva o tipo de foco que você encontrou. A sua proposta será discutida com a equipe técnica do projeto. Se aprovada, ela vai ser incorporada na lista Tipo de foco. Você não receberá no momento da proposta os 50 pontos pelo foco marcado. Mas, caso o novo tipo de foco for aprovado, você receberá 100 pontos pela inovação e mais 50 pela identificação.

    Outras questões relativas a marcar e eliminar focos podem ser esclarecidas lendo o Manual de Conduta do Dengue Torpedo.


   Por Torpedo
   -----------
    Para marcar um foco por Torpedo, você deve tirar a foto do foco que você encontrou. Em seguida, você deve enviar a localização e descrição do foco encontrado por mensagem de texto (SMS) para o número do Dengue Torpedo 021981865344. Salve a foto da foco em seu celular para depois carregá-la no site do Dengue Torpedo.

    Ex: Caixa d’água destampada na rua Portinari, 45
    Ex: Foco no pratinho de vaso em frente da casa na rua Roberto da Silveira, 150

    Após o envio do SMS, você vai receber uma das seguintes notificações no seu celular:

    • Se você já possui uma conta no Dengue Torpedo: Parabéns! O seu relato foi recebido e adicionado ao Dengue Torpedo.
    • Se você ainda não possui uma conta no Dengue Torpedo: Você ainda não tem uma conta. Registre-se no site do Dengue Torpedo.
    • Se você for um patrocinador ou verificador registrado no Dengue Torpedo: O seu perfil não está habilitado para o envio do Dengue Torpedo.

    Após receber a mensagem de sucesso em seu celular, você deve acessar sua conta do Dengue Torpedo de um computador e completar a marcação do foco na página 'Focos Marcados'.

    A mensagem que você enviou por SMS irá aparecer no topo da lista na página de 'Focos Marcados'. Para completar, pressione o botão verde Completar o foco. Você será direcionado para a página 'Completar o foco'.

    Nessa página, você deve preencher os campos com os dados solicitados na ordem seguinte:

    1. Escrever a localização no formato solicitado;
    A localização enviada por SMS deve ser preenchida no formato solicitado para ser identificado pelo mapa.

    2. Ajuste o marcador no mapa;
    O mapa pode não encontrar o seu endereço. Nesse caso, mova o marcador clicando na localização correta.

    3. Descrição da localização.
    Descreva onde o foco está localizado, se na laje, no quintal, na calçada do endereço, entre outras possíveis localizações.

    4. Carregue a imagem do foco encontrado.
    Clique no botão Escolher arquivo e selecione a imagem do foco encontrado.

    Após finalizar essas etapas, clique em Enviar!. Você será direcionado para a página 'Focos Marcados' onde você vai ver o seu relato com todas as informações preenchidas.

    Para concluir a marcação do foco, clique em Selecione o tipo de foco em verde e selecione o tipo de foco que você encontrou. Em seguida, clique no botão Enviar!. Após submeter o seu foco, o contador aparece com 48 horas e inicia a contagem do tempo restante para que o foco seja eliminado. Também nesse momento, você recebe 50 pontos e completa um DT Torpedo.


   Eliminando focos
   ----------------
    Para eliminar um foco, você precisa

    1. Acessar a página “Focos Marcados”
    2. Encontrar o foco que você eliminou na lista de focos Em aberto
    3. Carregar a foto do foco.
    Clique no botão Escolher arquivo e selecione a imagem do foco eliminado.
    4. Selecionar o método de eliminação.

    Após finalizar essas etapas, clique em Carregue!. A foto do foco eliminado será postada e o foco irá aparecer nos Focos eliminados.

    Com a ação finalizada os seus pontos serão automaticamente somados e você poderá verificar sua pontuação acessando a página “Meu Perfil”

    ATENÇÃO: Caso você tenha uma proposta para outro método de eliminação que não está na lista Método de eliminação, selecione Outro método. Você será direcionado para a página “Contato DT”. Nela, descreva o método que você propõe para eliminar o foco. A sua proposta será discutida com a equipe técnica do projeto. Se aprovada, ela vai ser incorporada na lista Método de eliminação com pontuação. Você não receberá no momento da proposta os pontos da eliminação do foco. Mas, caso o seu método for aprovado, você receberá 100 pontos pela inovação. Caso você consiga utilizar esse método para eliminar esse foco, você receberá a pontuação definida pela equipe técnica do projeto.

    Outras questões relativas a marcar e eliminar focos podem ser esclarecidas lendo o Manual de Conduta do Dengue Torpedo.


   Regras do jogo e verificação
   ----------------------------
    Como todo jogo, o Dengue Torpedo também tem suas regras. Algumas regras importantes são:

    1. O jogador deve selecionar na lista Tipo de foco o tipo que corresponde ao foco que ele encontrou. Caso não corresponda, o jogador não receberá os 50 pontos por marcar um foco.

    2. O jogador deve selecionar na lista Método de eliminação o método que corresponde ao tipo de foco já selecionado. Caso não corresponda, o jogador não receberá os pontos da eliminação.

    3. Após marcado, o foco deve ser eliminado em até 48 horas, conforme o contador em cada relato em aberto. Após esse tempo ele aparece como Tempo expirado.

    4. Para ganhar 1 DT Torpedo, o jogador deve ser enviar o SMS com a localização e completar o foco no site DT. Para mais informações, consulte Marcando um foco por torpedo.

    Os focos marcados e eliminados no Dengue Torpedo são constantemente verificados pela equipe do jogo e também pelos verificadores, que são os Agentes Comunitários de Saúde e os Agentes de Vigilância em Saúde.

    Se o seu relato de foco tiver o símbolo verde √, ele foi verificado e confirmado. Caso o seu relato de foco tiver o símbolo vermelho X, foi constatado um problema no seu relato. Nesse caso, você deve contatar a equipe do Dengue Torpedo no contato DT (http://www.denguetorpedo.com/feedbacks/new).


   Microblog
   ---------
    Uma das ferramentas do Dengue Torpedo é o microblog associado ao perfil de cada participante. Esses microblogs criam a rede social do Dengue Torpedo.

    Para publicar no microblog, basta ir ao seu perfil, digitar um título e descrever a sua ideia.

    Com o microblog você pode convidar os seus vizinhos para realizar ações coletivas em sua vizinhança, como mutirões de limpeza e de eliminação dos focos da dengue. Você também pode contar a sua experiência de combate dos focos de dengue.

    O microblog é o seu espaço de comunicação dentro do Dengue Torpedo.
    "
    ds.save(:validate => false)
  end



  ds = DocumentationSection.find_by_title("Como ganhar")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 6
    ds.title    = "Como ganhar"
    ds.content  = "Ganhando pontos
    ---------------
     No Dengue Torpedo cada jogador ganha pontos de acordo com as suas ações no combate da dengue. Por exemplo:


     Marcar um foco: 50 pontos.
     Eliminar um foco: 50 a 450 pontos de acordo com o método de eliminação do foco.
     Postar no mini blog: 5 pontos com máximo de 100 pontos por mês ou 20 postagens.
     Recrutar jogador: 50 pontos.


     Para saber quantos pontos você ganha eliminando diferentes tipos de foco, consulte a lista abaixo:

    | Tipo de Foco         | Método de Eliminação                               | Pontos |
    --------------------------------------------------------------------------------------
    |                          | Elimine fazendo furos no pratinho                | 200     |
    | Pratinho de planta | Prato removido (ou seja, não mais utilizado) | 200     |
    |                          | Coloque areia | 100 |
    |                          | Retire a água e esfregue para remover
                                  possíveis ovos (uma vez por semana).          | 50      |
    --------------------------------------------------------------------------------------
    | Pneu                  | Desfaça-se do pneu
                                 (entregue ao serviço de limpeza)                   | 50     |
    | Pneu                   | Arranje um uso alternativo para o pneu:
                                  preencha com terra e faça uma horta;
                                  preencha com areia, terra e cimento e utilize
                                  como degrau.                                             | 450   |
    | Pneu                   | Transferir o pneu sem água para um local
                                  coberto e seco.                                           | 100   |
    | Pneu                   | Cubra o pneu com algo que não se transforme
                                  em um foco potencial do mosquito.                | 100   |
    ------------------------------------------------
    | Lixo (recipientes inutilizados) | Jogá-los em uma lixeira bem tampada. | 0 |
    | Lixo (recipientes inutilizados) | Organize um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários. | 450 |
    | Lixo (recipientes inutilizados) | Participe de um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários. | 350 |
    ------------------------------------------------
    | Pequenos Recipientes utilizáveis, Garrafas de vidro, vasos, baldes, tigela de água de cachorro | Remova a água e esfregue uma vez por semana; ou, no caso de bebedouros de animais e aves, trocar a água e limpar diariamente. | 50 |
    | Pequenos Recipientes utilizáveis, Garrafas de vidro, vasos, baldes, tigela de água de cachorro | Virar de cabeça para baixo, secar e armazenar. | 50 |

    ------------------------------------------------
    | Grandes Recipientes Utilizáveis, Tonéis, outras depósitos de água, pias, galões d’água. | Cobrir a caixa d’água | 450 |
    | Grandes Recipientes Utilizáveis, Tonéis, outras depósitos de água, pias, galões d’água. | Vedar adequadamente com tapa e ou capa apropriada | 200 |
    | Grandes Recipientes Utilizáveis, Tonéis, outras depósitos de água, pias, galões d’água. | Outros recipientes: esfregue, seque, cubra ou sele. | 350 |
    ------------------------------------------------
    | Calha | Desentupir e limpar; | 150 |
    ------------------------------------------------
    | Registros abertos | Sele com cobertura impermeável para prevenir a penetração da água e ainda ter acesso ao registro. | 300 |
    | Registros abertos | Preencha com areia ou terra e mude o acesso à válvula. | 300 |
    | Registros abertos | Vedar. | 300 |
    ------------------------------------------------
    | Laje e terraços com água | Limpá-las. | 50 |
    ------------------------------------------------
    | Piscinas | Piscinas em uso: esfregue e limpe uma vez por semana | 350 |
    | Piscinas | Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde. | 350 |
    ------------------------------------------------
    | Poças d’água na rua | Elimine a água com rodo ou vassoura | 50 |
    ------------------------------------------------
    | Ralos | Jogue água sanitária ou desinfetante semanalmente. | 50 |
    | Ralos | Elimine entupimento | 50 |
    | Ralos | Vede ralos não utilizados | 50 |
    ------------------------------------------------
    | Plantas ornamentais que acumulam água (ex: bromélias). | Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água. | 50 |
    | Plantas ornamentais que acumulam água (ex: bromélias). | Retire a água acumulada nas folhas | 50 |
    | Plantas ornamentais que acumulam água (ex: bromélias). | Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água. | 50 |
    ------------------------------------------------



    Trocando pontos
    ---------------
    Por prêmios
    -----------
     No Dengue Torpedo, você joga, marcando e eliminando focos, e troca os seus pontos por prêmios.

     Os prêmios disponíveis aparecem na seção Prêmios da página principal. Você também pode visualizar os prêmios disponíveis na página 'Ganhe prêmios'.

     Trocar os seus pontos por prêmios é fácil. Você só precisa:

     1. Acessar a página 'Ganhe prêmios'.
     2. Encontrar o cupom do prêmio que você quer trocar pelos seus pontos.
     3. Clicar sobre a imagem ou título do cupom. Você será direcionado para a página dele.
     4. Ler a descrição e condições para retirar o prêmio.
     5. Clicar no botão verde Usar os meus pontos agora!.
     Esse botão só aparece nos prêmios que você tem pontos suficientes para resgatar.
     6. Confirmar o resgate dos pontos.
     7. Imprimir o cupom do prêmio.
     Nesse cupom estão suas informações pessoais, o código do prêmio, informações do patrocinador e data limite do resgate.
     8. Comparecer ao estabelecimento de porte do cupom impresso e de um documento válido com foto (ex: RG) para resgate do prêmio.

     ATENÇÃO: Você não pode desfazer a ação de utilizar os pontos. Uma vez resgatado, o seu prêmio deve ser retirado em até 7 dias no estabelecimento patrocinador ou conforme as instruções de resgate do cupom do prêmio.


    Por medalhas
    ------------
     Você ganha as medalhas automaticamente, assim que alcançar a pontuação necessária para cada uma. As medalhas aparecem na página 'Meu Perfil' e não é necessário resgatar ou utilizar pontos.

     Há cinco tipo de medalhas:

     De olho no mosquito - 100 pontos
     Exterminador de mosquitos - 450 pontos
     Guerreiro DT - 900 pontos
     Comunidade saudável - 1350 pontos
     Eu cuido da comunidade - 1800 pontos


    Restituindo créditos de celular pré-pago
    ----------------------------------------

     O valor utilizado para o envio do SMS será restituído, ou seja, devolvido para você em forma de recarga. Essa recarga acontece quando você atinge a quantidade de DT Torpedos requisitados por cada operadora, conforme tabela abaixo.

    | Operadora | Máximo creditado por mês (R$) | Quantidade DT Torpedos requisitados |
    -----------------------------------------------------------------------------------
    | Claro | R$ 13 | 17 |
    | Nextel | R$ 20 | 27 |
    | Oi | R$ 15 | 20 |
    | Tim | R$ 13 | 17 |
    | Vivo | R$ 15 | 20 |



     ATENÇÃO:
     * Lembre-se que você ganha um DT Torpedo a cada foco completo enviado por SMS.
     * Cada usuário terá direito a 1 (uma) restituição dos valores por mês.
     * A restituição é realizada automaticamente em forma de recarga de crédito para celulares pré-pagos.
     * A restituição é intransferível, ou seja, é válida somente para os números de celulares pré-pagos cadastrados no Dengue Torpedo.
     * O crédito ocorrerá em até 7 dias úteis (período sujeito à disponibilidade do sistema) assim que o usuário atingir a quantidade de DT Torpedos requisitados.


    Tipos de prêmios
    ----------------
     Você pode usar os seus pontos acumulados no Dengue Torpedo para ganhar prêmios individuais ou para a comunidade.

     * Individuais
     Cada prêmio requer uma quantidade de pontos. Confira a lista completa de prêmios   individuais na página 'Ganhe Prêmios'.

     * Comunidade
     Você pode usar os seus pontos para melhorar a sua vizinhança e ajudar a sua  comunidade. Confira a lista completa de prêmios para a  comunidade e as regras  específicas na página 'Ganhe Prêmios'.

     * Medalhas
     Você ganha as medalhas automaticamente. Confira os detalhes no tópico Trocando   pontos desse manual.


     Mais detalhes do sistema de troca de pontos por prêmios podem ser esclarecidos na seção 'Perguntas frequentes'.


    "
    ds.save(:validate => false)
  end



  ds = DocumentationSection.find_by_title("Como participar")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 7
    ds.title    = "Como participar"
    ds.content  = "O Dengue Torpedo está sendo lançado no bairro da Maré. Essa é uma iniciativa pioneira que se der certo será expandida para outros bairros da cidade. Dessa forma, apenas moradores da Maré podem participar dessa fase pioneira.

    Moradores
    ---------
     Qualquer morador da Maré convidado pela equipe do Dengue Torpedo ou por outro jogador pode participar. Para isso, basta se inscrever na página inicial e começar a jogar.

     Caso você tenha sido convidado por outro jogador, não se esqueça de marcá-lo completando as informações no campo  Alguém o convidou a se inscrever no DT?.

     Patrocinadores
     --------------
     Qualquer comerciante ou prestador de serviço pode participar do Dengue Torpedo fornecendo prêmios individuais ou para a comunidade. O seu comércio ou serviço terá uma página própria de patrocinador no site. Nessa página, os dados do seu negócio como logo, localização e telefone comercial irão aparecer. A página do patrocinador é um anúncio do seu negócio e fica visível a qualquer visitante do site. Caso você não tenha um logo digital, nossa equipe pode criá-lo de acordo com suas especificações. Esse logo digital é seu. Você pode usá-lo para outros fins.


     Verificadores
     -------------
     No Dengue Torpedo, alguns participantes têm um perfil especial de verificar identificação e eliminação de focos pelos jogadores. Na fase atual, o papel de verificação dos focos marcados é dos Agentes Comunitários de Saúde (ACS) e dos Agentes de Vigilância Sanitária (AVS).

     Os verificadores também podem ser convocados para mediar conflitos, auxiliar com informações técnicas e promover oficinas de promoção de saúde e vigilância epidemiológica para a Dengue.

     Saiba mais sobre essas atividades dos verificadores acessando 'Minha comunidade'.
    "

    ds.save(:validate => false)
  end


  ds = DocumentationSection.find_by_title("Minha comunidade")
  if ds.nil?
    ds          = DocumentationSection.new
    ds.order_id = 8
    ds.title    = "Minha comunidade"
    ds.content  = "A página 'Minha Comunidade' é onde você encontra as casas participantes e outros destaques da sua comunidade. É nessa página que você encontra notícias, oficinas e outras atividades."
    ds.save(:validate => false)
  end



  puts "\n" * 3
  puts "[ok] Done seeding /howto documentation"
  puts "-" * 80

end



def seed_breeding_sites_and_elimination_methods
  puts "-" * 80
  puts "[!] Seeding elimination types and methods..."
  puts "\n" * 3

  types_and_methods = [
    {
      :breeding_site_in_pt => "Pratinho de planta",
      :breeding_site_in_es => "Plato pequeño de maceta",
      :elimination_methods_in_pt => [
        {:method => "Elimine fazendo furos no pratinho", :points => 20},
        {:method => "Prato removido (ou seja, não mais utilizado)", :points => 20},
        {:method => "Coloque areia", :points => 20},
        {:method => "Retire a água e esfregue para remover possíveis ovos (uma vez por semana).", :points => 5}
      ],
      :elimination_methods_in_es => [
        {:method => "Elimine haciendo agujeros en el plato", :points => 20},
        {:method => "Plato removido (es decir, no se utilizará más)", :points => 20},
        {:method => "Coloque arena", :points => 20},
        {:method => "Retire el agua y limpie para remover posibles huevos (una vez por semana).", :points => 5}
      ]
    },

    {
      :string_id => BreedingSite::Types::TIRE,
      :breeding_site_in_pt => "Pneu",
      :breeding_site_in_es => "Llanta",
      :elimination_methods_in_pt => [
        {:method => "Desfaça-se do pneu (entregue ao serviço de limpeza)", :points => 5},
        {:method => "Arranje um uso alternativo para o pneu: preencha com terra e faça uma horta; preencha com areia, terra e cimento e utilize como degrau.", :points => 45},
        {:method => "Transferir o pneu sem água para um local coberto e seco.", :points => 10},
        {:method => "Cubra o pneu com algo que não se transforme em um foco potencial do mosquito.", :points => 10}
      ],
      :elimination_methods_in_es => [
        {:method => "Deshágase de la llanta (entregue al servicio de limpieza)", :points => 5},
        {:method => "Organice un uso alternativo para la llanta: rellenar con tierra para hacer una jardinera; rellenar con tierra y hacer una hortaliza; rellenar con arena, tierra y cemento y utilizar como punto de paso.", :points => 45},
        {:method => "Transferir la llanta a un lugar cubierto y seco.", :points => 10},
        {:method => "Cubra la llanta con algo que no se transforme en un foco potencial de mosquitos.", :points => 10}
      ]
    },

    {
      :breeding_site_in_pt => "Lixo (recipientes inutilizados)",
      :breeding_site_in_es => "Basura (recipientes inutilizados)",
      :elimination_methods_in_pt => [
        {:method => "Jogá-los em uma lixeira bem tampada.", :points => 0},
        {:method => "Organize um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", :points => 45},
        {:method => "Participe de um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", :points => 35}
      ],

      :elimination_methods_in_es => [
        {:method => "Tire la basura en un basurero bien tapado.", :points => 0},
        {:method => "Organice una campaña para limpiar el barrio (coordinado por los Agentes de Vigilancia Sanitaria) Ejemplo: Busque lugares donde no tienen acceso los barrenderos de la comunidad", :points => 45},
        {:method => "Únase a una campaña para limpiar el barrio (coordinado por los Agentes de Vigilancia Sanitaria) Ejemplo: en lugares donde no tienen acceso los barrenderos de la comunidad. ", :points => 35}
      ]
    },

    {
      :string_id => BreedingSite::Types::SMALL_CONTAINER,
      :breeding_site_in_pt => "Pequenos Recipientes utilizáveis Garrafas de vidro, vasos, baldes, tigela de água de cachorro",
      :breeding_site_in_es => "Botellas de pequeños contenedores de vidrio utilizable, jarrones, cubetas, tazón de agua de mascotas",
      :elimination_methods_in_pt => [
        {:method => "Remova a água e esfregue uma vez por semana; ou, no caso de bebedouros de animais e aves, trocar a água e limpar diariamente.", :points => 5},
        {:method => "Elimine fazendo furos no pratinho", :points => 20}
      ],

      :elimination_methods_in_es => [
        {:method => "Remueva el agua y talle una vez por semana; en caso de ser bebedero de animales o aves, cambiar el agua diariamente.", :points => 5},
        {:method => "Elimine fazendo furos no pratinho", :points => 20}
      ]
    },

    {
      :string_id => BreedingSite::Types::LARGE_CONTAINER,
      :breeding_site_in_pt => "Grandes Recipientes Utilizáveis Tonéis, outras depósitos de água, pias, galões d’água.",
      :breeding_site_in_es => "Recipientes grandes utilizables, toneles, galones, piletas, otros depósitos de agua.",
      :elimination_methods_in_pt => [
        {:method => "Cobrir a caixa d’água", :points => 45},
        {:method => "Vedar adequadamente com tapa e ou capa apropriada", :points => 20},
        {:method => "Outros recipientes: esfregue, seque, cubra ou sele.", :points => 35}
      ],

      :elimination_methods_in_es => [
        {:method => "Cubrir la caida del agua", :points => 45},
        {:method => "Tapar adecuadamente con tapa o con una capota apropiada", :points => 20},
        {:method => "Otros recipientes: limpie, seque, cubra o selle.", :points => 35}
      ]
    },

    {
      :breeding_site_in_pt => "Calha",
      :breeding_site_in_es => "Quebrada o charco",
      :elimination_methods_in_pt => [
        {:method => "Desentupir e limpar", :points => 15}
      ],
      :elimination_methods_in_es => [
        {:method => "Destapar y limpiar", :points => 15}
      ]
    },

    {
      :breeding_site_in_pt => "Registros abertos",
      :breeding_site_in_es => "Registros abiertos",
      :elimination_methods_in_pt => [
        {:method => "Sele com cobertura impermeável para prevenir a penetração da água e ainda ter acesso ao registro.", :points => 30},
        {:method => "Preencha com areia ou terra e mude o acesso à válvula.", :points => 30},
        {:method => "Vedar.", :points => 30}
      ],
      :elimination_methods_in_es => [
        {:method => "Selle con una cubiert impermeable para prevenir la penetración de agua sin perder acceso al registro.", :points => 30},
        {:method => "Llene con arena o tierra y cambie de lugar el acceso a la válvula.", :points => 30},
        {:method => "Cancelación de registro.", :points => 30}
      ]
    },

    {
      :breeding_site_in_pt => "Laje e terraços com água",
      :breeding_site_in_es => "Loza y terrazas con agua",
      :elimination_methods_in_pt => [
        {:method => "Limpá-las.", :points => 30}
      ],

      :elimination_methods_in_es => [
        {:method => "Limpá-las.", :points => 30}
      ]
    },

    {
      :breeding_site_in_pt => "Piscinas",
      :breeding_site_in_es => "Piscinas",
      :elimination_methods_in_pt => [
        {:method => "Piscinas em uso: esfregue e limpe uma vez por semana", :points => 35},
        {:method => "Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde.", :points => 35}
      ],

      :elimination_methods_in_es => [
        {:method => "Piscinas em uso: esfregue e limpe uma vez por semana", :points => 35},
        {:method => "Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde.", :points => 35}
      ]
    },

    {
      :breeding_site_in_pt => "Poças d’água na rua",
      :breeding_site_in_es => "Pozas de agua en la calle",
      :elimination_methods_in_pt => [
        {:method => "Elimine a água com rodo ou vassoura", :points => 5}
      ],

      :elimination_methods_in_es => [
        {:method => "Elimine el agua con una escobilla de goma o una escoba", :points => 5}
      ]
    },

    {
      :breeding_site_in_pt => "Ralos",
      :breeding_site_in_es => "Drenajes",
      :elimination_methods_in_pt => [
        {:method => "Jogue água sanitária ou desinfetante semanalmente.", :points => 5},
        {:method => "Elimine entupimento", :points => 5},
        {:method => "Vede ralos não utilizados", :points => 5}
      ],

      :elimination_methods_in_es => [
        {:method => "Añada cloro o desinfectante semanalmente.", :points => 5},
        {:method => "Elimine la obstrucción", :points => 5},
        {:method => "Suspenda los drenajes no utilizados", :points => 5}
      ]
    },

    {
      :breeding_site_in_pt => "Plantas aquáticas em vaso de água",
      :breeding_site_in_es => "Plantas acuáticas en vasos de agua",
      :elimination_methods_in_pt => [
        {:method => "Retire a água acumulada nas folhas", :points => 5},
        {:method => "Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água.", :points => 5}
      ],

      :elimination_methods_in_es => [
        {:method => "Retire el agua acumulada en las hojas", :points => 5},
        {:method => "Regar semanalmente con agua clorada con una cucharada sopera por cada litro de agua.", :points => 5}
      ]
    }
  ]


  types_and_methods.each do |types_hash|
    # Find (or create) the breeding site.
    bs = BreedingSite.find_or_create_by_description_in_pt( types_hash[:breeding_site_in_pt] )
    bs.description_in_es = types_hash[:breeding_site_in_es]
    bs.string_id         = types_hash[:string_id]
    bs.save!

    # Find (or create) each method.
    types_hash[:elimination_methods_in_pt].each_with_index do |m, index|
      em                   = EliminationMethod.find_or_create_by_method( m[:method] )
      em.description_in_pt = m[:method]
      em.description_in_es = types_hash[:elimination_methods_in_es][index][:method]
      em.points            = m[:points]
      em.breeding_site_id  = bs.id
      em.save!
    end
  end



  puts "\n" * 3
  puts "[ok] Done seeding elimination types and methods"
  puts "-" * 80
end





# NOTE: We NEVER want to overwrite the coordinator changes in production
# or staging with the seed.
if Rails.env.test? || Rails.env.development?
  seed_breeding_sites_and_elimination_methods()

  puts "\n" * 3
  puts "[...] Seeding /howto documentation in Spanish"
  puts "-" * 80


  seed_manual()



      ds = DocumentationSection.find_by_title("Como se cadastrar")
      ds.title_in_es = "Como registrarse"
      ds.content_in_es = "¡Crear su registro en Dengue Torpedo (DT) es fácil!
      Para iniciar el registro, la página inicial solicita que proporcione
      su Email, nombre, apellido, contraseña para accesar su cuenta (mínimo
      de 4 caractéres), y confirmación de contraseña.
      Para proseguir, haga clic en el botón de Regístrese. Usté será
      dirigido a la página de Configuraciones donde ustéd completará su registro
      añadiendo un poco más de información personal.
      ATENCIÓN: Usted debe escribir su nombre como consta en un documento
      válido (ej. credencial de elector) que será validado para
      intercambiar sus puntos por premios."
      ds.save(:validate => false)


      ds = DocumentationSection.find_by_title("Como completar sua conta")
      ds.title_in_es = "Como completar su cuenta"
      ds.content_in_es = "Los datos que usted proporcionó en la página inicial estarán
      pre-escritos en la página de Configuraciones. Añada usted los datos
      que falten para poder personalizar su cuenta.
      Los campos de información incluyen la identificación del jugador
      jugador, colonia, correo electrónico, número y tipo de cuenta de
      teléfono celular.
      Si usted se registró en el sitio porque un amigo o vecino lo invitó,
      no olvide mencionar a esa persona seleccionandola en el campo junto
      a la frase '¿Alguien lo invitó a registrarse en DT?'"
      ds.save(:validate => false)



      ds = DocumentationSection.find_by_title("Barra de navegação")
      ds.title_in_es = "Barra de navegación"
      ds.content_in_es = "En la barra superior de navegación usted encontrará los siguientes enlaces
      para accesar a cada
      página del sitio.

      * Mi perfíl
      * Mi comunidad
      * Equipos
      * Focos marcados

      La barra puede ser accesada en cualquier momento. Ahí aparecen todos
      los enlaces desde el momento en que usted entra en la página de DT.
      Una vez llevado a cabo su registro, entre en su cuenta en la página
      inicial escribiendo su correo electrónico (parte superior derecha de
      la página inicial). Una vez conectado en su cuenta, usted puede hacer
      cambios en sus datos personales, unirse o dejar equipos, etc.
      Para ello, haga clic en Configuraciones."
      ds.save(:validate => false)


      ds = DocumentationSection.find_by_title("O que é um foco?")
      ds.title_in_es = "¿Qué es un foco?"
      ds.content_in_es = "Un foco de infección, o simplemente foco, es un lugar con agua
      estancada, generalmente limpio, donde los mosquitos ponen sus huevos.
      Los focos se pueden clasificar como:

      * Focos activos: Contienen pupas o larvas de mosquito

      * Focos potenciales: Posibles criaderos sin pupas o larvas visibles.

      Una vez encontrados y reportados, los dos tipos de focos son llamados
      'Focos marcados' y les corresponde la misma puntuación. Es decir, en
      DT no hay distinción entre focos activos y potenciales."
      ds.save(:validate => false)


      ds = DocumentationSection.find_by_title("Como jogar")
      ds.title_in_es = "¿Como jugar?"
      ds.content_in_es = "Hay varias formas de jugar. Usted puede ganar puntos al:

      * Marcar focos;

      * Eliminar focos;

      * Publicar en el blog información relevante para la comunidad;

      * Invitar a amigos y vecinos a jugar;

      * Ganar puntos;

      * Intercambiar puntos por premios;

      * Participar en las atividades promovidas por Dengue Torpedo.

      Una vez conectado en su cuenta de DT, usted podrá visualizar los focos

      marcados. Hay dos tipos de focos marcados, abiertos y

      eliminados. Los focos que siguen abiertos pueden ser eliminados por

      cualquier jugador para ganar puntos.

      Visualización de focos de infección

      ------------------

      Al accesar la página que de los 'Focos Marcados' ustéd verá

      reportes de los focos abiertos y eliminados. La localizacón de los focos se

      mostrará en un mapa de su comunidad. Cada reporte tiene una

      dirección, fotos, descripción del tipo de foco con método de

      eliminación, y otros datos. Los focos abiertos poseen un contador que

      muestra el tiempo restante para eliminarlos.

      El mapa cuenta con una herramienta de acercamiento para

      visualizar mejor los focos. La lista de focos se ajusta de manera

      dinámica con el ajuste de enfoque en el mapa. Para

      disminuir la escala del mapa (acercarmiento), haga clic en el

      signo '+' y haga clic en el signo '-' para alejarse. La lista de

      focos también puede ajustarse arrastrando el mapa. Para arrastrar el

      mapa, coloque el cursor sobre el mapa, haga clic sin soltar con el

      botón derecho, y arrastre.

      La página 'Focos Marcados' tiene tres filtros para visualizar los

      focos: Todos, Abiertos, Eliminados. Haga clic en los páneles para

      visualizar los focos marcados por categoría.

      ¿Como marcar focos?

      --------------

      Usted puede marcar focos a través del sitio (www.denguetorpedo.com) o

      enviando un mensaje de texto (SMS) desde su celular.


      Como marcar un foco en el sitio de Dengue Torpedo

      ---------------------------

      Para marcar un foco, usted tiene que accesar a su cuenta y hacer clic

      en la frase 'Focos Marcados' en la barra de navegación. Al entrar en

      la página de los focos usted podrá visualizar una lista de los focos

      marcados en su región.

      Para marcar un foco, haga clic en el botón de 'Marcar un foco'. Usted

      será direccionado a una nueva página en la que podrá llenar los campos

      solicitados:

      1. Dirección del foco localizado. La dirección debe ser llenada en el

      formato solicitado para ser identificada en el mapa.

      2. Descripción del lugar. La descripción debe incluir detalles como

      'en la loza del patio', 'en la acera', etc.

      3. Cargue una imagen del foco encontrado. Haga clic en el botón de

      'Escoger archivo' o en 'Seleccionar una imagen del foco encontrado'.

      4. Seleccione un tipo de foco. Seleccione el tipo de foco encontrado

      de acuerdo con las opciones de la lista.

      5. Ajuste el marcador en el mapa. Puede que el sistema de mapeo no

      encuentre en el mapa. En ese caso, mueva el marcador haciendo clic en

      la localización correcta.

      Para finalizar esa etapa, haga clic en 'Enviar'. Usted será dirigido a

      la página 'Focos Marcados' donde va a ver su relato con toda la

      información que usted proporcionó. En caso de que usted tenga una

      cuenta en Facebook o Twitter, usted puede compartir el foco haciendo

      clic en el botón de 'Compartir' o 'Twitear'. Después de someter la

      información de su foco recibirá 50 puntos y la página mostrará un

      contador que comienza en 48 horas mostrando el tiempo restante antes

      de que el foco sea eliminado será mostrado.

      ATENCIÓN: En caso de que usted quera marcar un foco cuyo tipo

      no está en la lista de Tipos de foco, seleccione 'Otro tipo de

      foco'. Ustéd será dirigido a la página 'Contacto DT'. En ella,

      describa el Tipo de foco. Su propuesta será discutida con el equipo

      técnico del proyecto. De ser aprobada, el nuevo tipo de foco será

      incorporado en la lista, usted recibirá 100 puntos por la inovación y

      50 más por la identificación.



      Otras preguntas relativas a marcar o eliminar focos pueden ser

      esclarecidas leyendo el Manual de Conducta de Dengue Torpedo.




      Como marcar un foco por mensaje de texto

      -----------

      Para marcar un foco utilizando mensajes de texto (SMS) usted debe

      tomar una fotografía del foco y guárdela en su celular. Acto

      seguido, mande un mensaje de texto con la localización y descripción

      del foco encontrado a un número de Dengue Torpedo (##). Usted debe

      subir la fotografía del foco utilizando el sitio de Dengue Torpedo

      en cuanto tenga acceso a una computadora.

      Ej. Caja de agua descubierta en la calle Independencia #45

      Ej. Foco en plato pequeño de mazeta frente a la casa en el camino

      Emiliano Zapata # 150

      Después de enviar el SMS, usted va a recibir una de las siguientes

      notificaciones en su celular:

      - Si ya tiene una cuenta de Dengue Torpedo: '¡Enhorabuena! Su informe

      ha sido recibido'

      - Si aún no tiene una cuenta en Dengue Torpedo: 'Usted no tiene una

      cuenta. Regístrese en el sitio de Dengue Torpedo'

      - Si usted es un patrocinador o verificador registrado en Dengue

      Torpedo: 'Su perfil no está habilitado para envíos en Dengue Torpedo'

      Después de recibir el mensaje de éxito en su celular, usted debe

      accesar su cuenta de Dengue Torpedo desde una computadora y completar

      el marcado del foco en la página 'Focos Marcados'.

      El mensaje que ustéd envió por SMS aparecerá en la parte superior de

      la lista en la página de 'Focos Marcados'. Para completar el

      reporte, presione el botón verde 'Completar el foco'. Usted será

      direccionado a la página 'Completar el foco'. En esa página, usted

      debe llenar campos como los mencionados a continuación:

      1. Dirección del foco localizado. La dirección debe ser llenada en

      el formato solicitado para ser identificado en el mapa.

      2. Descripción del lugar. Ej. en la loza del

      patio, en la acera, etc

      3. Cargue una imagen del foco encontrado. Haga clic en el botón de

      'Escoja un archivo'

      4. Seleccione el tipo de foco de acuerdo con las opciones de la

      lista.

      5. Ajuste el marcador del mapa. Si no es posible encontrar su dirección

      en el mapa, mueva el marcador haciendo clic en la ubicación correcta.

      Después de finalizar los pasos anteriores, haga clic en

      'Enviar'. Usted será direccionado a la página 'Focos Marcados' donde

      usted verá su reporte con todas la información proporcionada.

      En caso de que usted tenga una cuenta de Facebook o Twitter, usted

      puede compartir el foco en su cuenta. Para eso, basta hacer clic en el

      botón 'Compartir o Twitear' y mostrarlo a todos sus amigos.

      Después de someter su foco, el contador aparece con 48 horas que

      representan el tiempo restante para que el foco sea eliminado. También

      en ese momento usted recibirá 50 puntos si completa un mensaje de

      texto en DT.


      Eliminando focos

      ----------------

      Para reportar un foco eliminado siga los siguientes pasos.

      1. Acesar a la página 'Focos Marcados'

      2. Encontrar el foco que usted eliminó en la lista de focos abiertos

      3. Cargar una foto del foco haciendo clic en el botón de 'Seleccione

      un archivo que contenga una imágen del foco eliminado'

      4. Después de finalizar los pasos anteriores, haga clic en 'Cargue'

      La foto del foco eliminado se eliminará y reaparecerá en la página

      'Focos Eliminados'.

      5. En caso usted tenha una cuenta en Facebook o Twitter, usted puede

      compartir el foco en su cuenta haciendo click en el botón de

      'Compartir o twitear con tus amigos'

      Cuando haya finalizado sus puntos serán sumados automáticamente y

      usted podrá verificar su puntuación accesando a la página 'Mi perfil'

      ATENCIÓN: En caso de que usted tenga una propuesta para otro método

      de eliminación que no esté en la lista de métodos de DT, seleccione

      'Otro método'. Su propuesta será discutida con el equipo técnico del

      proyecto. Si es aprobada, será incorporada en la lista de Métodos de

      eliminación compo puntuación. Usted recibirá al momento

      una propuesta de eliminación de enfoque. En el caso de que

      sea aprobada la propuesta, usted recibirá 100 puntos por la

      inovación.

      Otras preguntas relativas a como marcar y eliminar focos pueden ser

      exclarecidas leyendo el Manual de Conducta de Dengue Torpedo.

      Reglas del juego y verificación

      ----------------------------

      Como todo juego, Dengue Torpedo también tiene sus reglas. Algunas de

      las reglas más importantes son:

      Un jugador debe seleccionar

      1. El jugador debe seleccionar el Tipo de Foco de la lista de acuerdo

      con el tipo de foco que encontró. En caso que no

      correspondan el tipo seleccionado y el tipo encontrado, el jugador

      no recibirá los 50 puntos por marcar el foco.

      2. El jugador debe seleccionar de la lista de 'Método de eliminación' el

      método que corresponde al tipo de foco seleccionado. Si el método no

      corresponde con el tipo de foco, el jugador no recibirá los puntos por

      la eliminación.

      3. Después de marcado, el foco debe ser eliminado dentro de las

      siguientes 48 horas, conforme al contador de cada foco marcado pero no

      eliminado abierto. Después de las 48 horas, el tiempo expira y no será

      posible eliminar el foco para obtener puntos en DT.

      4. Para ganar 1 DT Torpedo, el jugador debe enviar un SMS con la

      información del foco y completar el reporte en el sitio de Dengue

      Torpedo. Para más información, consulte 'Marcando un foco por SMS'.

      Los focos marcados o eliminados en Dengue Torpedo son constantemente

      verificados por el equipo de juego y también por los verificadores,

      que son los Agentes Comunitarios de Salud y los Agentes de Vigilancia

      de Salud.

      Si hay una palomita (símbolo verde √) en el reporte del foco, el foco

      fue verificado y confirmado. En caso de que su relato de foco tenga

      una cruz (o tache, X), entonces hubo un problema con su reporte. En

      esos casos, debe contactar al equipo de Dengue Torpedo usando el

      enlace 'Contacto DT' (http://www.denguetorpedo.com/feedbacks/new).


      Microblog

      ---------

      Una de las herramientas de Dengue Torpedo es el microblog asociado al

      perfil de cada participante. Esos microblogs crean una red social de

      Dengue Torpedo. El microblog es su espacio de comunicación dentro

      de Dengue Torpedo. Con el microblog usted puede comunicarse con sus

      vecinos para realizar acciones conjuntas en su colonia, tales como

      jornadas vecinales de vigilancia y limpieza para eliminar brotes

      potenciales de dengue. Para publicar un microblog, basta ir a su perfil,
      teclear un título y

      escribir su idea."
      ds.save(:validate => false)



      ds = DocumentationSection.find_by_title("Como ganhar")
      ds.title_in_es = "¿Cómo ganar?"
      ds.content_in_es = %Q(Puntos

      En Dengue Torpedo cada jugador gana puntos de acuerdo con sus acciones

      de combate al dengue. Por ejemplo,

      Marcar un foco: 50 puntos.

      Eliminar un foco: 50 a 450 puntos de acuerdo con el método de

      eliminación del foco.

      Publicar en el miniblog: 5 puntos con un máximo de 100 pontos por o 20
      publicaciones.

      Reclutar un jugador: 50 puntos.

      Para saber cuantos puntos ustéd gana eliminando diferentes tipos de

      foco, consulte la lista siguiente:

      Tipo de Foco: Plato pequeño de mazeta

      Método de eliminación

      - Eliminación haciendo agujeros en el plato. 200 pontos

      - Plato removido. 200 puntos

      - Colocación de arena. 100 puntos

      - Retirado de agua y lavado para remover posibles huevecillos (una vez

      por semana). 50 puntos

      Tipo de foco: Llanta

      Método de eliminación:

      - Remoción y desecho de la llanta (entregado al servicio de

      limpieza). 50 puntos.

      - Arreglar para darle uso alternativo a la llanta: llenado con tierra

      para hacer una hortaliza o jardinera, llenado con arena, tierra, o

      cemento y utilización como piso. 450 puntos

      - Transferir la llanta sin agua y sin desechos a un local cubierto y

      seco. 100 puntos

      - Cubra la llanta con algo que para que no se transforme en un foco

      potencial de mosquito. 100 puntos.

      Tipo de Foco: Recipientes no utilizables y basura

      Método de eliminación:

      - Enjuague y guardado en almacén bien tapado. 0 puntos

      - Organice una jornada vecinal de limpieza en lugares donde no tengan

      acceso los servicios de limpieza locales (coordinada por los Agentes

      de Vigilancia Sanitaria). 450 puntos

      - Participe en una jornada vecinal de limpieza en lugares donde no tengan

      acceso los servicios de limpieza locales (coordinada por los Agentes

      de Vigilancia Sanitaria). 350 puntos

      Tipo de Foco: Pequeños recipientes utilizables, garrafas de vidrio,

      vasos, baldes, tinas de agua, etc.

      Método de eliminación:

      - Remueva el agua y friegue una vez por semana. En caso de bebederos

      de animales y aves, cambiar el agua y limpiar diariamente. 50 puntos.

      - Girar el recipiente para tirar sus contenidos. Secar y almacenar. 50
      puntos


      Tipo de Foco: Grandes recipientes utilizables, toneles, otros

      depósitos de agua, piletas, galones.

      Método de eliminación:

      - Cubrir de la caida de agua. 450 puntos

      - Tapar o cancelar automáticamente con una tapa o capota

      apropiada. 200 puntos

      - Otros recipientes: Lave, seque, cubra. 350 puntos.

      Tipo de Foco: Caño

      Método de eliminación:

      - Destapar y limpiar. 150 puntos

      Tipo de Foco: Registros abiertos

      Método de eliminación:

      - Selle con una cobertura impermeable para prevenir la penetración de

      agua sin perder acceso al registro. 300 puntos

      - Llenado con arena o tierra y cambio del registro o acceso a

      válvula a otro lugar. 300 puntos

      - Llenado con arena o tierra y cancelación del registro. 300 puntos

      Tipo de Foco: Charcos u otras acumulaciones de agua

      Método de eliminación:

      - Limpiado. 50 puntos.

      Tipo de Foco: Piscinas

      Método de eliminación:

      - Piscinas en uso: Limpie y talle una vez por semana. 350 puntos

      - Piscinas que no están en uso: Limpie, talle, y deshágace del

      agua. Si la piscina es de plástico, desmonte y guarde. 350 puntos.

      Tipo de Foco: Pozas de agua estancada

      Método de eliminación:

      - Elimine el agua y remueva la basura. 50 puntos

      Tipo de Foco: Pozas de agua estancada

      Método de eliminación:

      - Enguague con agua limpia y desinfecte semanalmente. 50 puntos

      - Elimine el estancamiento. 50 puntos.

      - Cancele los huecos no utilizados. 50 puntos



      Tipo de Foco: Plantas ornamentales que acumulan agua

      Método de eliminación:

      - Regar semanalmente con agua clorada con una cucharada sopera por

      cada litro de agua. 50 puntos

      - Retire agua acumulada en las hojas. 50 puntos

      Cambiando puntos

      - Por premios

      En Dengue Torpedo usted juega marcando y eliminando focos, e

      intercambia sus puntos por premios. Los premios disponibles aparecen

      en la sección de Premios de la página principal. Usted también puede

      visualizar los premios disponibles en la página "Gane premios".

      Intercambiar sus puntos por premios es fácil. Usted sólo debe:

      1. Accesar a la página "Gane premios"

      2. Encuentre un cupón de premio que usted quiera intercambiar por sus

      puntos.

      3. Haga clic sobre la imagen o título del cupón. Usted será

      redireccionado a la página del premio.

      4. Lea la descripción del premio y las condiciones para sacarlo.

      5. Haga clic en el botón verde "Usar mis puntos ahora"

      6. Confirmar el uso de los puntos.

      7. Imprimir un cupón de premio. En ese cupón estará su información

      personal, el código del premio, informacion de los patrocinadores y

      datos del retiro.

      8. Ir a un establecimiento autorizado con el cupón impreso y una

      identificación válida con foto (ej. IFE).

      Atención: Usted no puede dar paso atrás una vez que haya utilizado los

      puntos. Una vez apartado, su premio debe ser recogido antes de 7 días

      en el establecimiento del patrocinador siguiendo las instrucciones de

      retiro en su cupón.


      - Por medallas



      Usted gana las medallas automáticamente cuando alcanza la puntuación

      necesaria para cada una. Las medallas aparecen en la página "Mi

      perfil" y no es necesario intercambiar o utilizar los puntos.

      Hay cinco tipos de medallas:

      Enemigo de los mosquitos - 100 puntos

      Exterminador de mosquitos - 450 puntos

      Guerrero DT - 950 puntos

      Guardia de la comunidad - 1350 puntos

      Paladín de la comunidad - 1800 puntos

      - Restituyendo créditos de celular pre-pago

      El valor utilizado para envío de SMS será restituido, o sea, devuleto

      a usted en forma de recarga. Esa recarga entra en firme cuando usted

      acumula la cantidad de textos de Dengue Torpedo requeridos por cada

      operadora, conforme a convenio.


      | Operadora | Máximo acreditado por mês ($) | Quantidad de SMSs de Dengue
      Torpedo requeridos |

      Claro.................. Crédito de $ --...................... 17 SMSs
      DT

      Nextel................ Crédito de $ --....................... 27 SMSs
      DT

      Oi....................... Crédito de $ --..................... 20
      SMSs DT

      Tim........... .........Crédito de $ --...................... 17 SMSs
      DT

      Vivo........... ........Crédito de $ --...................... 20 SMSs
      DT

      Atención:

      - Acuerdese que usted se gana un SMS de Dengue Torpedo por cada foco

      completo enviado por SMS.

      - Cada usuario tendrá derecho a una recarga dos veces por mes.

      - La restitución es realizada automáticamente en forma de recarga de

      crédito para celulares pre-pagados.

      - Las recargas son intransferibles. Es decir, son válidad para los

      números de celulares pre-pagados registrados en Dengue Torpedo.

      - El crédito será otorgado en hasta 7 días (periodo sujeto a

      disponibilidad de sistema) de forma que el usuario tiene que estar

      atento a la cantidad de SMSs de DT que haya hecho.

      - Tipos de premios

      Usted puede usar sus puntos acumulados en Dengue Torpedo para ganar

      premios individuales o comunitarios.

      * Individuales

      Cada premio requiere de una cantidad de puntos. La lista de premios y

      los correspondientes puntos esta en la página "Gane Premios"

      * Comunitarios

      Usted puede usar sus puntos compartiéndolos con sus vecionos y ayudar

      a su comunidad. Consulte la lista completa de premios para las

      comunidades y las reglas específicas en la página "Ganhe Premios".

      * Medallas

      Usted gana las medallas automáticamente. Consulte los detallesen el

      tema "Intercambiando premios" de este manual.

      Mas detalles del sistema de intercambio de puntos pueden ser

      esclarecidos en la sección de preguntas frecuentes.)
      ds.save(:validate => false)


      ds = DocumentationSection.find_by_title("Como participar")
      ds.title_in_es = "¿Cómo participar?"
      ds.content_in_es = %Q(Dengue Torpedo fue lanzado por primera vez en el barrio de Maré, en

      Río. Esta iniciativa será expandida para otros barrios de ciudades. De

      esa forma los moradores de Maré puede participar de esa fase

      pionera.

      Moradores

      ---------

      Cualquier morador de Maré invitado por el equipo de Dengue Torpedo o

      por otro jugador puede participar. Para eso, basta inscribirse en la

      página inicial y comenzar a jugar. En caso de que usted sea

      invitado por otro jugador, hay que completar la información de

      registro en los campos requeridos y mencionar que alguien lo invitó

      a inscribirse a DT.

      Patrocinadores

      --------------

      Cualquier comerciante o prestador de servicios puede participar en

      Dengue Torpedo proporcionando premios individuales o comunitarios.

      Sea comercio o lugar de servicios, tendrá una página propia de

      patrocinador en el sitio de Dengue Torpedo. En esa página apareceran

      los datos del negocio como logo, lugar y teléfono. La página del

      patrocinador tendrá un anuncio de su negocio que verá cualquier

      persona que visite el sitio de Dengue Torpedo. Si su negocio no tiene

      un logo digital, nuestro equipo puede crearlo de acuerdo con sus

      especificaciones. Ese logo digital será suyo, y podrá usarlo para

      cualquier fin que a usted le convenga.

      Verificadores

      -------------

      En Dengue Torpedo algunos participantes tienen un perfil especial

      de verificadores de indentificación y eliminación de focos. En su

      fase actual, el papel del verificador de focos marcados lo fungen

      los agentes comunitarios de la salud (ACS) y los agentes de

      vigilancia sanitaria (AVS).

      Los verificadores también pueden ser convocados para mediar

      conflictos, auxiliar con informaciónes técnicas y promover oficinas

      de vigilancia epidemiológica para Dengue.



      Sepa más sobre esas actividades de los verificadores accesando "Mi
      comunidad")
      ds.save(:validate => false)

      ds = DocumentationSection.find_by_title("Minha comunidade")
      ds.title_in_es = "Mi comunidad"
      ds.content_in_es = %Q(La página "Mi comunidad" es donde usted encontrará las casas

      participantes y otros asuntos de su comunidad (noticias, y otras

      actividades).)
      ds.save(:validate => false)







  puts "\n" * 3
  puts "[ok] Done seeding /howto documentation in Spanish"
  puts "-" * 80

end

#------------------------------------------------------------------------------
