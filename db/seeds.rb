# encoding: UTF-8

require "#{Rails.root}/db/seeds/breeding_site"

#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

n = Neighborhood.find_by_name("Maré")
if n.nil?
  c = Country.find_country_by_name("Brazil")
  n                   = Neighborhood.new
  n.name              = "Maré"
  n.city              = "Rio de Janeiro"
  n.state_string_id   = "RJ"
  n.country_string_id = c.alpha2
  n.save!
end

# Tepalcingo neighborhood is our first neighborhood in Mexico.
# It is located in the city of Tepalcingo, in the state of Morelos,
# in the country of Mexico.
n = Neighborhood.find_by_name("Tepalcingo")
if n.nil?
  c = Country.find_country_by_name("Mexico")
  n                   = Neighborhood.new
  n.name              = "Tepalcingo"
  n.city              = "Tepalcingo"
  n.state_string_id   = "MOR"
  n.country_string_id = c.alpha2
  n.save!
end


puts "\n" * 3
puts "[ok] Done seeding neighborhoods..."
puts "-" * 80

#------------------------------------------------------------------------------
# Elimination types and methods

seed_breeding_sites_and_elimination_methods()

#------------------------------------------------------------------------------

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

  ds.save!
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
  ds.save!
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
  ds.save!
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
  ds.save!
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
  ds.save!
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
  ds.save!
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

  ds.save!
end


ds = DocumentationSection.find_by_title("Minha comunidade")
if ds.nil?
  ds          = DocumentationSection.new
  ds.order_id = 8
  ds.title    = "Minha comunidade"
  ds.content  = "A página 'Minha Comunidade' é onde você encontra as casas participantes e outros destaques da sua comunidade. É nessa página que você encontra notícias, oficinas e outras atividades."
  ds.save!
end



puts "\n" * 3
puts "[ok] Done seeding /howto documentation"
puts "-" * 80
