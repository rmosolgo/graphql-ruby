# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::DefinitionDependencies do
  describe "fragment resolution bug GIANT arrays of the same AST node" do
    let(:schema_defn) { <<-GRAPHQL
      schema {
  query: Query
  mutation: RootMutation
}
type Ac10339026 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  na13121605: String
  de66827894: String
  ca76269766: Boolean
  ne95083037: Me25904200
  me15958901(
    fi24236244: Int
    af43427568: String
    la23779556: Int
    be51344852: String
  ): Me25904200Connection
}
type Ac10339026Connection {
  ed79758833: [Ac10339026Edge]
  pa24440567: PageInfo!
}
type Ac10339026Edge {
  no17534244: Ac10339026
  cu58102045: String!
}
input ActivatePlanInput {
  cl64010677: String
  id: ID!
  ta5918883: ID!
}
type ActivatePlanPayload {
  cl64010677: String
  ia72224747: IAP
  ta45677779: Ta34557648
}
type Admin implements Node {
  id: ID!
  ac24408163(
    fi24236244: Int
    af43427568: String
    la23779556: Int
    be51344852: String
  ): Ac10339026Connection
  ac74199398(id: ID!): Ac10339026!
  us12652646(
    fi24236244: Int
    af43427568: String
    la23779556: Int
    be51344852: String
  ): Us44827341Connection
  us71422177(id: ID!): Us44827341!
}
type AttachedFile {
  ex2227970: Boolean
  si60171863: Int
  cr64799723: String
  ur15075386: String
  fi98999055: String
  pa12113791: String
  co23641714: String
  up85682678: String
  st17622422: [AttachedFileStyle]
}
type AttachedFileStyle {
  na13121605: String!
  ex2227970: Boolean!
  si60171863: Int!
  ur15075386: String!
}
input BuildIAPInput {
  cl64010677: String
  id: ID!
}
type BuildIAPPayload {
  cl64010677: String
  ia72224747: IAP
  do42594910: Do76642608
}
input CancelDo76642608BuildInput {
  cl64010677: String
  id: ID!
}
type CancelDo76642608BuildPayload {
  cl64010677: String
  do35211570: Do76642608Build
}
type Co5807770 implements Node, Re17665062 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co79208324: String
  co86784415: Co68529874
  cr64799723: Da85167052
  us71422177: Us44827341
  pe6416159: Pe81388412
  in98532332: In12743319
  de6033584: Da85167052
  ca64579777: Boolean
}
interface Co68529874 {
  id: ID!
  co77824378: [Co5807770]
  in98532332: In12743319
}
input CompleteTa34557648Input {
  cl64010677: String
  id: ID!
  st18370808: String
  co77824378: String
}
type CompleteTa34557648Payload {
  cl64010677: String
  ta45677779: Ta34557648
}
input CreateAc10339026Input {
  cl64010677: String
  na13121605: String!
  de66827894: String
}
type CreateAc10339026Payload {
  cl64010677: String
  ac26908578: Ac10339026Edge
  ne17460057: Ac10339026
}
input CreateCo5807770Input {
  cl64010677: String
  co3064273: ID!
  co79208324: String
}
type CreateCo5807770Payload {
  cl64010677: String
  ne55153642: Co5807770
}
input CreateIC280374352011Input {
  cl64010677: String
}
type CreateIC280374352011Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne70259872: IC280374352011
}
input CreateIC280374352013Input {
  cl64010677: String
  pr42308928: String
}
type CreateIC280374352013Payload {
  cl64010677: String
  in98532332: In12743319
  ne84110848: IC280374352013
}
input CreateIC28037435203Input {
  cl64010677: String
  pr42308928: String
}
type CreateIC28037435203Payload {
  cl64010677: String
  in98532332: In12743319
  ne83042245: IC28037435203
}
input CreateIC28037435207Input {
  cl64010677: String
  pe72005623: ID
  js62930677: String
}
type CreateIC28037435207Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne28385456: IC28037435207
}
input CreateIC8372611Input {
  cl64010677: String
  in54222291: ID
  pe72005623: ID
  re33961140: String
  ta9786614: Boolean
  av50010664: Boolean
  su58324129: String
  re35327074: String
  op76137115: String
  re30516181: String
  lo49821039: String
  lo70103048: String
  pu75995855: String
  su53440558: String
  su43235194: String
  su94427113: String
  su42032990: String
  or10813494: String
  fi81392394: String
  fi88472486: String
  re98966088: String
  re22929080: String
}
input CreateIC47863915Input {
  cl64010677: String
  qt85111356: Int
  re69124076: String
  re38815744: String
  pr45086289: String
  it23162215: String
  re68451243: String
  re3408083: String
  or79669623: String
  et91792684: String
  co31408242: Float
}
type CreateIC47863915Payload {
  cl64010677: String
  ic34087692: IC8372611
  ne75625080: IC47863915
}
type CreateIC8372611Payload {
  cl64010677: String
  in98532332: In12743319
  ne30295157: IC8372611
}
input CreateIC28037435215AInput {
  cl64010677: String
  pe72005623: ID!
  js62930677: String
}
type CreateIC28037435215APayload {
  cl64010677: String
  pe6416159: Pe81388412
  ne53658018: IC28037435215A
}
input CreateIC28037435215Input {
  cl64010677: String
  pe72005623: ID
  js62930677: String
}
type CreateIC28037435215Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne52966081: IC28037435215
}
input CreateIC28037435234Input {
  cl64010677: String
  pe72005623: ID!
  js62930677: String
}
input CreateIC28037435234Ob69073202Input {
  cl64010677: String
  st42493719: String
  ta73026065: String
}
type CreateIC28037435234Ob69073202Payload {
  cl64010677: String
  in98532332: In12743319
  ne90839033: IC28037435234Ob69073202
}
type CreateIC28037435234Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne54911596: IC28037435234
}
input CreateIn12743319Input {
  cl64010677: String
  na13121605: String!
  ac58206883: ID!
  st97285675: String
  ci83825827: String
  st61999631: String
  de66827894: String
  in43992751: String!
  in88418543: String!
  ti57061136: String!
  la75757940: Float
  ln49010101: Float
}
type CreateIn12743319Payload {
  cl64010677: String
  us71422177: Us44827341
  ne4755431: In12743319
  ac74199398: Ac10339026
  er85452588: String
  su63480918: String
}
input CreateIn12743319Us44827341Input {
  cl64010677: String
  ro5651591: String
}
type CreateIn12743319Us44827341Payload {
  cl64010677: String
  in98532332: In12743319
  ne97637637: In12743319Us44827341
}
input CreateLo31830362Input {
  cl64010677: String
  na13121605: String
  pe72005623: ID!
  lo78149830: String
  ad36421314: String
  di80241846: String
  ge38334027: Float
  ge45596195: Float
  in44329409: Float
  in7313058: Float
  us78141759: Boolean
}
type CreateLo31830362Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne64386104: Lo31830362
}
input CreateMe37548318Input {
  cl64010677: String
  me98378050: String
  ti22359276: String
  pu19446084: String
  st84506348: String
  lo93400274: String
  at60024201: String
  pr20601567: String
  st18370808: String
  se14469802: Int
}
type CreateMe37548318Payload {
  cl64010677: String
  in98532332: In12743319
  ne1017379: Me37548318
}
input CreateOb69073202Input {
  cl64010677: String
  ic85485403: ID
  nu99206985: Int
  bo41275142: String
}
type CreateOb69073202Payload {
  cl64010677: String
  ic8585616: IC28037435202
  ne43727141: Ob69073202
  do42594910: Do76642608
}
input CreateOr51769208Input {
  cl64010677: String
  qu70134088: String
}
type CreateOr51769208Payload {
  cl64010677: String
  in98532332: In12743319
  ne91552549: Or51769208
}
input CreateOr56512494Input {
  cl64010677: String
  pe72005623: ID!
  or92279086: String
  or92170116: String
  se23242573: String
  or45052357: String
  po69599994: String
  po73767570: String
  po15294071: String
  ha13657663: Boolean
  re98841034: ID
}
type CreateOr56512494Payload {
  cl64010677: String
  in98532332: In12743319
  pe6416159: Pe81388412
  ne91476026: Or56512494
  re8037555: Or56512494
}
input CreatePe81388412Input {
  cl64010677: String
  in54222291: ID!
  st84506348: String!
  en6965241: String!
  se33019677: Int!
}
type CreatePe81388412Payload {
  cl64010677: String
  ne37472914: Pe81388412
  in98532332: In12743319
  er85452588: String
  in45134312: String
  su63480918: String
  wa23850620: String
}
input CreatePr6305523Input {
  cl64010677: String
  pr40346269: String
  pr56963008: String
}
type CreatePr6305523Payload {
  cl64010677: String
  in98532332: In12743319
  ne47406669: Pr6305523
}
input CreateRe87939570Input {
  cl64010677: String
  ro5651591: String
  in54222291: ID!
  re12271851: String!
}
type CreateRe87939570Payload {
  cl64010677: String
  in98532332: In12743319
  ne85996386: Re87939570
  er85452588: String
}
input CreateTa34557648Input {
  cl64010677: String
  ti22359276: String
  ta99029522: String
  co24804489: String
  ge84666105: String
  is14552457: Boolean
}
type CreateTa34557648Payload {
  cl64010677: String
  in98532332: In12743319
  ne13676909: Ta34557648
}
input CreateUs44827341Input {
  cl64010677: String
  fi45889694: String
  la48591314: String
  em7635361: String
  co11026667: String
  is44038920: String
}
type CreateUs44827341Payload {
  cl64010677: String
  us83152718: Us44827341Edge
  ne59082474: Us44827341
}
input CreateWe31448640Input {
  cl64010677: String
  pe72005623: ID
  js62930677: String
}
type CreateWe31448640Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne61790456: We31448640
}
input CreateWo39743646Input {
  cl64010677: String
  pe72005623: ID!
  ob24425028: ID
  bo41275142: String
  br28211757: String
  di45360760: String
}
type CreateWo39743646Payload {
  cl64010677: String
  pe6416159: Pe81388412
  ne99194634: Wo39743646
  ob55737262: Ob69073202
}
scalar Da85167052
input DeactivateOr51769208Input {
  cl64010677: String
  id: ID!
}
type DeactivateOr51769208Payload {
  cl64010677: String
  pe6416159: Pe81388412
  or13798486: Or51769208
  er85452588: String
}
input DeleteCo5807770Input {
  cl64010677: String
  id: ID!
}
type DeleteCo5807770Payload {
  cl64010677: String
  co79208324: Co5807770
}
input DeleteMe25904200Input {
  cl64010677: String
  id: ID!
}
type DeleteMe25904200Payload {
  cl64010677: String
  me14087375: ID
  ac74199398: Ac10339026
  er85452588: String
  su63480918: String
}
input DisableRe87939570Input {
  cl64010677: String
  id: ID!
}
type DisableRe87939570Payload {
  cl64010677: String
  re12271851: Re87939570
}
type Do76642608 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  do80320870: [Do76642608Build]
  cu59454027: Do76642608Build
  ti22359276: String
  se33019677: Int
  ac74199398: Ac10339026
  pe6416159: Pe81388412
  ph70000366: String
  st2364951: String
  st64011510: String
  re39416463: String
  re23893079: String
  pr58172091: String
  pr43448131: String
  in65734548: String
  in88703485: Boolean
  in64277499: Boolean
  up99646626: AttachedFile
  ed80171588: AttachedFile
  do18404151: Do68383654
  in61013859: [Op25306523]
  ve97234604: String
  ta18646551: [Ta34557648]
}
type Do76642608Build implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  do42594910: Do76642608
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  sh38342156: Boolean!
  ve67492145: Int
  bu40201598: String
  bu80922901: String
  bu52129391: String
  bu83787569: String
  fi31312785: AttachedFile
  re76403487: Re93847135
}
union Do68383654 = IAP | IC280374352011 | IC28037435202 | IC28037435234 | IC28037435203 | IC280374352013 | IC8372611
input FinanceSignIC8372611Input {
  cl64010677: String
  id: ID!
}
type FinanceSignIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
type IAP implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319!
  do40826006: String
  do42594910: Do76642608!
  ac26147843: String
  ca28168144: Boolean!
}
type IC280374352011 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  pr18457416: String
  ac74199398: Ac10339026
  pe6416159: Pe81388412
  do42594910: Do76642608
  cu48336070: String
  pr48435289: String
  pr42308928: String
  pr27289993: String
  pr35168918: String
  ma14140505: AttachedFile
}
type IC280374352013 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  pr42308928: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
}
type IC28037435202 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  co98470979: String
  pr18457416: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
  ob36783077: [Ob69073202]
  ne14123799: Int!
  ne88047118: Int!
}
type IC28037435203 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  pr42308928: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
}
type IC28037435207 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  na13121605: String
  pr18457416: String
  pr42308928: String
  st18370808: String
  tm88759018: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
}
type IC8372611 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
  re33961140: String
  ta9786614: Boolean
  av50010664: Boolean
  su58324129: String
  re1577640: Us44827341
  re35327074: String
  op26570726: Us44827341
  op76137115: String
  re38656786: Us44827341
  re30516181: String
  lo28122311: Us44827341
  lo49821039: String
  lo70103048: String
  pu75995855: String
  su53440558: String
  su43235194: String
  su94427113: String
  su42032990: String
  or10813494: String
  fi31483069: Us44827341
  fi81392394: String
  fi88472486: String
  re83715937: Us44827341
  re98966088: String
  re22929080: String
  ic75684522: [IC47863915]
  it12502306: Int
}
type IC47863915 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  ac74199398: Ac10339026
  ic34087692: IC8372611
  qt85111356: Int
  re69124076: String
  re38815744: String
  pr45086289: String
  it23162215: String
  re68451243: String
  re3408083: String
  or79669623: String
  et91792684: String
  co31408242: Float
}
type IC28037435215 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  na13121605: String
  pr18457416: String
  pr42308928: String
  st18370808: String
  tm86881211: String
  pm62267400: String
  pm95592995: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
  wo78236512: [Wo39743646]
}
type IC28037435215A implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  na13121605: String
  pr18457416: String
  pr42308928: String
  tm58333732: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
  ic14179679: IC28037435215
}
type IC28037435234 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  pr18457416: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
  ob36783077: [Ob69073202]
  st18370808: String
  pr42308928: Da85167052
  na13121605: String
  ic37349860: [IC28037435234Ob69073202]
}
type IC28037435234Ob69073202 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  st42493719: String
  ta73026065: String
  se14469802: Int
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  ic10471260: IC28037435234
  ob55737262: Ob69073202
  ob1622515: Int
  ob10605811: String
}
type Ic53116404 {
  le2428721: String!
  ca22789822: String!
  ic30860072: String!
}
type In12743319 implements Node, Re17665062, RootInterface {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  ro61531259: Root
  na13121605: String
  st97285675: String
  en6262250: String
  ci83825827: String
  st61999631: String
  de66827894: String
  st18370808: String
  op3452993: Int
  in43992751: String
  in84065120: String
  in88418543: String
  in50753817: String
  ti57061136: String
  ar89226604: Boolean
  la75757940: Float
  ln49010101: Float
  cr64799723: String
  up85682678: String
  cr97154127: Us44827341
  cu88853562: Pe81388412
  in55728785: [In12743319Us44827341]
  re32204721: [Re87939570]
  re77974667: [Re93847135]
  zo55859074: [Op25306523]
  in78329674: [Op25306523]
  in65228081: [Op25306523]
  ne76810580: Pe81388412
  pe41873033: [Pe81388412]
  ne86493808: Re87939570
  me41544303: [Me37548318]
  se11563851: [Op25306523]
  us12652646: [Us44827341]
  ic18460074: [IC8372611]
  or22533521: [Or56512494]
  ic67904255: Or56512494
  co19534841: [Or56512494]
  ps44799902: Or56512494
  ls74839307: Or56512494
  os84202837: Or56512494
  fs88912463: Or56512494
  ic56185271: [Ta34557648]
}
type In12743319Us44827341 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319!
  ro5651591: String
  ro44561793: String
  us71422177: Us44827341!
}
input InitiateRequestIC8372611Input {
  cl64010677: String
  id: ID!
}
type InitiateRequestIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
input In14312521Input {
  cl64010677: String
  fi45889694: String
  la48591314: String
  em7635361: String!
  co11026667: String
  ro5651591: String!
  ac58206883: String!
}
type In14312521Payload {
  cl64010677: String
  me55414505: Me25904200Edge
  ne12429519: Me25904200
  us83152718: Us44827341Edge
  ne59082474: Us44827341
  er85452588: String
  in45134312: String
}
type La61501759 {
  la75757940: Float
  ln49010101: Float
  is48132563: Boolean
}
type Lo31830362 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319!
  na13121605: String
  lo78149830: String
  lo65132882: String
  ad36421314: String
  di80241846: String
  se33019677: Int
  ge38334027: Float
  ge45596195: Float
  in44329409: Float
  in7313058: Float
  us78141759: Boolean
  pe6416159: Pe81388412!
  lo47160861: [Op25306523]
  la81264064: La61501759
  in8255281: La61501759
  ge51516948: La61501759
  ge94469868(ad36421314: String): La61501759
}
input Lo34839197SignIC8372611Input {
  cl64010677: String
  id: ID!
}
type Lo34839197SignIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
type Me37548318 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  me98378050: String
  me78810059: String
  ti22359276: String
  pu19446084: String
  st84506348: Da85167052
  en6965241: Da85167052
  fa49545673: String
  lo93400274: String
  at60024201: String
  pr20601567: String
  st18370808: String
  st44341589: String
  se14469802: Int
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  pr25251808: [Ta34557648]
  me52652491: [Ta34557648]
}
type Me25904200 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  ro5651591: String
  us71422177: Us44827341
  ac74199398: Ac10339026
  ca71329535: Boolean
  ca64579777: Boolean
  ro99242007: [Op25306523]
}
type Me25904200Connection {
  ed79758833: [Me25904200Edge]
  pa24440567: PageInfo!
}
type Me25904200Edge {
  no17534244: Me25904200
  cu58102045: String!
}
interface Node {
  id: ID!
}
type Ob69073202 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  nu99206985: Int
  se14469802: Int
  bo41275142: String
  st42493719: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  ic8585616: IC28037435202
  is76059106: Boolean
  wo78236512: [Wo39743646]
}
input Op82901357SignIC8372611Input {
  cl64010677: String
  id: ID!
}
type Op82901357SignIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
type Op25306523 {
  va91762118: String
  la6548921: String
}
type Or51769208 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  qu70134088: String
  re8037555: Or56512494
  or1284175: String
  or84881531: Or56512494
  us71422177: Us44827341
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  is57126270: Boolean
  or89912099: String
  se23608228: String
}
type Or56512494 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  or92279086: String
  or92170116: String
  or84152698: String
  se23242573: String
  se26248958: String
  or45052357: String
  po69599994: String
  po73767570: String
  po15294071: String
  is4899704: Boolean
  ac74199398: Ac10339026
  pe6416159: Pe81388412
  or13798486(pe72005623: String!): Or51769208
  or72921245(pe72005623: String!): [Or51769208]
  su69714672(pe72005623: String!): [Or56512494]
  de39020813: Or51769208
  as42755754: Or51769208
}
type PageInfo {
  ha69898107: Boolean!
  ha73564901: Boolean!
  st19001244: String
  en16514667: String
}
type Pe81388412 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319!
  pe9782144: String
  pe55369799: String
  st84506348: String
  st17096224: String
  en6965241: String
  en5126028: String
  me41544303: [Me37548318]
  du11695287: Int!
  se33019677: Int!
  st21213328: String
  en48615549: String
  cu98139104: AttachedFile
  ca55117032: Boolean!
  pe94771150: String
  do27806622: [Do76642608]
  ne70165531: Do76642608
  lo2500528: [Lo31830362]
  ne48393815: Lo31830362
  or72921245: [Or51769208]
  or89912099: String
  in81147590: [Or51769208]
  ic79076099: [Or51769208]
  uc48005601: [Or51769208]
  re43019657: [Or51769208]
  fs18821324: [Or51769208]
  ls37179279: [Or51769208]
  os88649022: [Or51769208]
  ps28902898: [Or51769208]
  re91740321: [Or51769208]
  ob36783077: [Ob69073202]
  ia72224747: IAP
  wo78236512: [Wo39743646]
  ta18646551: [Ta34557648]
  or22533521: [Or56512494]
  ic4973828: [IC28037435215]
  ic93878993: [IC28037435215A]
  ic95554315: [IC28037435234]
  op77315177: [Or51769208]
  op2850181: [Or51769208]
  ta45677779(ta99029522: ID!): Ta34557648
  ic8585616: IC28037435202
  ic11234176: IC28037435203
  ic73631313: [IC28037435207]
  we97854155: [We31448640]
}
type Pr6305523 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  ac74199398: Ac10339026
  pe6416159: Pe81388412
  pr98925071: Pr52415888
  pr56963008: String
}
union Pr52415888 = IC8372611 | Me37548318
input Profi31312785UpdateInput {
  cl64010677: String
  id: ID!
  co11026667: String!
  fi45889694: String!
  la48591314: String!
}
type Profi31312785UpdatePayload {
  cl64010677: String
  us71422177: Us44827341
}
type Query implements Node {
  id: ID!
  no17534244(
    id: ID!
  ): Node
  ro61531259: Root
}
input ReactivateOr51769208Input {
  cl64010677: String
  id: ID!
}
type ReactivateOr51769208Payload {
  cl64010677: String
  pe6416159: Pe81388412
  or13798486: Or51769208
  er85452588: String
}

interface Re17665062 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
}
input Re40026779Input {
  cl64010677: String
  fi45889694: String!
  la48591314: String!
  em7635361: String!
  co11026667: String!
  re12271851: String!
}
type Re40026779Payload {
  cl64010677: String
  re70587746: String
  ac37045925: String
  in54222291: ID
  er85452588: String
  ro61531259: Root
}
type Re87939570 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319!
  ro5651591: String
  ro99242007: [Op25306523]!
  re12271851: String
  di94541472: String
}
input RejectIC8372611Input {
  cl64010677: String
  id: ID!
}
type RejectIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
type Re93847135 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  re35242737: String!
  ar72165630: String
  se33019677: Int!
  ji85471066: String
  st25110972: String
  co24804489: String
  st18370808: String!
  co32666358: Int!
  se93095581: Int
  re21363658: AttachedFile
}
input Re83489748Input {
  cl64010677: String
  em7635361: String!
}
type Re83489748Payload {
  cl64010677: String
  su63480918: Boolean!
  er85452588: String
}
input Re29388902SignIC8372611Input {
  cl64010677: String
  id: ID!
}
type Re29388902SignIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
type Root implements Node {
  id: ID!
  cu50706598: Us44827341
  re76403487(id: ID!): Re93847135
  ac74199398(id: ID!): Ac10339026
  in98532332(id: ID!): In12743319
  lo93400274(id: ID!): Lo31830362
  in7885687(id: ID!): In12743319Us44827341
  re12271851(id: ID!): Re87939570
  do42594910(id: ID!): Do76642608
  do35211570(id: ID!): Do76642608Build
  pe6416159(id: ID!): Pe81388412
  me21551016(id: ID!): Me37548318
  ta45677779(id: ID!): Ta34557648
  in267573: [In12743319]
  ad25477692: Admin
  ic34087692(id: ID!): IC8372611
  wo70541676(id: ID!): Wo39743646
  ic14179679(id: ID!): IC28037435215
  ic10471260(id: ID!): IC28037435234
  ic44408915(id: ID!): IC28037435215A
  ic77618414(id: ID!): IC28037435207
  we50181698(id: ID!): We31448640
  co79208324(id: ID!): Co5807770
}

interface RootInterface {
  ro61531259: Root
}
type RootMutation {
  si86502868(input: Si1460278Input!): Si1460278Payload
  si42545221(input: Si90904137Input!): Si90904137Payload
  re98772298(input: Re40026779Input!): Re40026779Payload
  re62230041(input: Re83489748Input!): Re83489748Payload
  pr63830047(input: Profi31312785UpdateInput!): Profi31312785UpdatePayload
  cr31491344(input: CreateUs44827341Input!): CreateUs44827341Payload
  up43241137(input: UpdateUs44827341Input!): UpdateUs44827341Payload
  se2434487(input: SetPa61416252Input!): SetPa61416252Payload
  cr14404434(input: CreateAc10339026Input!): CreateAc10339026Payload
  up23233025(input: UpdateAc10339026Input!): UpdateAc10339026Payload
  in68134427(input: In14312521Input!): In14312521Payload
  up39311811(input: UpdateMe25904200Input!): UpdateMe25904200Payload
  de48776025(input: DeleteMe25904200Input!): DeleteMe25904200Payload
  cr18285927(input: CreateIn12743319Input!): CreateIn12743319Payload
  up39661996(input: UpdateIn12743319Input!): UpdateIn12743319Payload
  cr93790513(input: CreatePe81388412Input!): CreatePe81388412Payload
  up50065860(input: UpdatePe81388412Input!): UpdatePe81388412Payload
  up52561971(input: UpdateDo76642608Input!): UpdateDo76642608Payload
  up45396713(input: UploadDo18507649sInput!): UploadDo18507649sPayload
  ca70122838(input: CancelDo76642608BuildInput!): CancelDo76642608BuildPayload
  bu14746294(input: BuildIAPInput!): BuildIAPPayload
  cr98703396(input: CreateIn12743319Us44827341Input!): CreateIn12743319Us44827341Payload
  up41398170(input: UpdateIn12743319Us44827341Input!): UpdateIn12743319Us44827341Payload
  cr24057256(input: CreateRe87939570Input!): CreateRe87939570Payload
  di99756910(input: DisableRe87939570Input!): DisableRe87939570Payload
  cr15352835(input: CreateLo31830362Input!): CreateLo31830362Payload
  up16208142(input: UpdateLo31830362Input!): UpdateLo31830362Payload
  up71136410(input: UpdateIC28037435202FieldInput!): UpdateIC28037435202FieldPayload
  up23920538(input: UpdateIC28037435202Input!): UpdateIC28037435202Payload
  cr87983374(input: CreateOb69073202Input!): CreateOb69073202Payload
  up12213555(input: UpdateOb69073202Input!): UpdateOb69073202Payload
  cr79851910(input: CreateIC28037435234Input!): CreateIC28037435234Payload
  up12178071(input: UpdateIC28037435234Input!): UpdateIC28037435234Payload
  cr80380383(input: CreateIC280374352011Input!): CreateIC280374352011Payload
  up79366163(input: UpdateIC280374352011Input!): UpdateIC280374352011Payload
  up37568553(input: UpdateIC280374352011FieldInput!): UpdateIC280374352011FieldPayload
  up17258571(input: UploadIC280374352011Ma914423Input!): UploadIC280374352011Ma914423Payload
  cr34403827(input: CreateMe37548318Input!): CreateMe37548318Payload
  up38003476(input: UpdateMe37548318Input!): UpdateMe37548318Payload
  co99115061(input: CompleteTa34557648Input!): CompleteTa34557648Payload
  cr80425584(input: CreateTa34557648Input!): CreateTa34557648Payload
  up86907105(input: UpdateTa34557648Input!): UpdateTa34557648Payload
  cr45281475(input: CreateOr51769208Input!): CreateOr51769208Payload
  up61152303(input: UpdateOr51769208Input!): UpdateOr51769208Payload
  up95890413(input: UpdateOr51769208Us44827341Input!): UpdateOr51769208Us44827341Payload
  de92259535(input: DeactivateOr51769208Input!): DeactivateOr51769208Payload
  re62715557(input: ReactivateOr51769208Input!): ReactivateOr51769208Payload
  cr56669731(input: CreateOr56512494Input!): CreateOr56512494Payload
  up49200993(input: UpdateOr56512494Input!): UpdateOr56512494Payload
  cr15653103(input: CreateIC28037435203Input!): CreateIC28037435203Payload
  up74955137(input: UpdateIC28037435203Input!): UpdateIC28037435203Payload
  cr20748199(input: CreateIC280374352013Input!): CreateIC280374352013Payload
  up29340364(input: UpdateIC280374352013Input!): UpdateIC280374352013Payload
  cr71735751(input: CreateIC8372611Input!): CreateIC8372611Payload
  up13479303(input: UpdateIC8372611Input!): UpdateIC8372611Payload
  re53474395(input: RejectIC8372611Input!): RejectIC8372611Payload
  in251437(input: InitiateRequestIC8372611Input!): InitiateRequestIC8372611Payload
  op17004237(input: Op82901357SignIC8372611Input!): Op82901357SignIC8372611Payload
  re19835447(input: Re29388902SignIC8372611Input!): Re29388902SignIC8372611Payload
  lo45245253(input: Lo34839197SignIC8372611Input!): Lo34839197SignIC8372611Payload
  fi73919421(input: FinanceSignIC8372611Input!): FinanceSignIC8372611Payload
  ac88506344(input: ActivatePlanInput!): ActivatePlanPayload
  cr82443256(input: CreateIC47863915Input!): CreateIC47863915Payload
  up79651412(input: UpdateIC47863915Input!): UpdateIC47863915Payload
  up91989994(input: UpdateOb69073202OperationalityInput!): UpdateOb69073202OperationalityPayload
  cr20088602(input: CreateWo39743646Input!): CreateWo39743646Payload
  up18596216(input: UpdateWo39743646Input!): UpdateWo39743646Payload
  up94716967(input: UpdateWo39743646Or56512494Input!): UpdateWo39743646Or56512494Payload
  up40485712(input: UpdateSt9001101iesInput!): UpdateSt9001101iesPayload
  cr3003405(input: CreateIC28037435234Ob69073202Input!): CreateIC28037435234Ob69073202Payload
  up58884042(input: UpdateIC28037435234Ob69073202Input!): UpdateIC28037435234Ob69073202Payload
  cr9775859(input: CreateIC28037435215Input!): CreateIC28037435215Payload
  up89746737(input: UpdateIC28037435215Input!): UpdateIC28037435215Payload
  cr68433447(input: CreateIC28037435215AInput!): CreateIC28037435215APayload
  up14788987(input: UpdateIC28037435215AInput!): UpdateIC28037435215APayload
  cr59056265(input: CreateIC28037435207Input!): CreateIC28037435207Payload
  up74806207(input: UpdateIC28037435207Input!): UpdateIC28037435207Payload
  cr76692921(input: CreateWe31448640Input!): CreateWe31448640Payload
  up19398170(input: UpdateWe31448640Input!): UpdateWe31448640Payload
  cr37100819(input: CreateCo5807770Input!): CreateCo5807770Payload
  up51558407(input: UpdateCo5807770Input!): UpdateCo5807770Payload
  de1427199(input: DeleteCo5807770Input!): DeleteCo5807770Payload
  cr5179644(input: CreatePr6305523Input!): CreatePr6305523Payload
  up31037955(input: UpdatePr6305523Input!): UpdatePr6305523Payload
}
input SetPa61416252Input {
  cl64010677: String
  id: ID!
  pa98520299: String!
  pa78315395: String!
}
type SetPa61416252Payload {
  cl64010677: String
  er85452588: String
  us71422177: Us44827341
}
input Si1460278Input {
  cl64010677: String
  em7635361: String!
  pa98520299: String!
}
type Si1460278Payload {
  cl64010677: String
  ac37045925: String
  me67662486: String
}
input Si90904137Input {
  cl64010677: String
}
type Si90904137Payload {
  cl64010677: String
  ro61531259: Root
  su63480918: Boolean
}
type Ta34557648 implements Node, Re17665062 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  ti22359276: String
  de66827894: String
  ta99029522: String
  ta22631630: String
  co24804489: String
  ge84666105: String
  is14552457: Boolean
  st18370808: String
  st44341589: String
  co77824378: String
  se14469802: Float!
  ac74199398: Ac10339026!
  in98532332: In12743319!
  pe6416159: Pe81388412
  pr98925071: Pr52415888
  st7473349: [Op25306523]
  ne9057505: Ta34557648
}
input UpdateAc10339026Input {
  cl64010677: String
  id: ID!
  na13121605: String
  de66827894: String
}
type UpdateAc10339026Payload {
  cl64010677: String
  ac74199398: Ac10339026
}
input UpdateCo5807770Input {
  cl64010677: String
  id: ID!
  co79208324: String
  co94338400: String
}
type UpdateCo5807770Payload {
  cl64010677: String
  co79208324: Co5807770
}
input UpdateDo76642608Input {
  cl64010677: String
  id: ID!
  in65734548: String
  in64277499: Boolean
  in88703485: Boolean
}
type UpdateDo76642608Payload {
  cl64010677: String
  do42594910: Do76642608
}
input UpdateIC280374352011FieldInput {
  cl64010677: String
  id: ID!
  fi401342: String!
  va91762118: String!
}
type UpdateIC280374352011FieldPayload {
  cl64010677: String
  ic17062660: IC280374352011
  do42594910: Do76642608
}
input UpdateIC280374352011Input {
  cl64010677: String
  id: ID!
}
type UpdateIC280374352011Payload {
  cl64010677: String
  ic17062660: IC280374352011
}
input UpdateIC280374352013Input {
  cl64010677: String
  id: ID!
  pr42308928: String
}
type UpdateIC280374352013Payload {
  cl64010677: String
  ic51046488: IC280374352013
}
input UpdateIC28037435202FieldInput {
  cl64010677: String
  id: ID!
  fi401342: String!
  va91762118: String!
}
type UpdateIC28037435202FieldPayload {
  cl64010677: String
  ic8585616: IC28037435202
  do42594910: Do76642608
}
input UpdateIC28037435202Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateIC28037435202Payload {
  cl64010677: String
  ic8585616: IC28037435202
}
input UpdateIC28037435203Input {
  cl64010677: String
  id: ID!
  pr42308928: String
}
type UpdateIC28037435203Payload {
  cl64010677: String
  ic11234176: IC28037435203
}
input UpdateIC28037435207Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateIC28037435207Payload {
  cl64010677: String
  ic77618414: IC28037435207
  pe6416159: Pe81388412
}
input UpdateIC8372611Input {
  cl64010677: String
  id: ID!
  re33961140: String
  ta9786614: Boolean
  av50010664: Boolean
  su58324129: String
  re35327074: String
  op76137115: String
  re30516181: String
  lo49821039: String
  lo70103048: String
  pu75995855: String
  su53440558: String
  su43235194: String
  su94427113: String
  su42032990: String
  or10813494: String
  fi81392394: String
  fi88472486: String
  re98966088: String
  re22929080: String
}
input UpdateIC47863915Input {
  cl64010677: String
  id: ID!
  qt85111356: Int
  re69124076: String
  re38815744: String
  pr45086289: String
  it23162215: String
  re68451243: String
  re3408083: String
  or79669623: String
  et91792684: String
  co31408242: Float
}
type UpdateIC47863915Payload {
  cl64010677: String
  ic194822: IC47863915
}
type UpdateIC8372611Payload {
  cl64010677: String
  ic34087692: IC8372611
}
input UpdateIC28037435215AInput {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateIC28037435215APayload {
  cl64010677: String
  ic44408915: IC28037435215A
  pe6416159: Pe81388412
}
input UpdateIC28037435215Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateIC28037435215Payload {
  cl64010677: String
  ic14179679: IC28037435215
  pe6416159: Pe81388412
}
input UpdateIC28037435234Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
input UpdateIC28037435234Ob69073202Input {
  cl64010677: String
  id: ID!
  st42493719: String
  ta73026065: String
}
type UpdateIC28037435234Ob69073202Payload {
  cl64010677: String
  ic79768219: IC28037435234Ob69073202
}
type UpdateIC28037435234Payload {
  cl64010677: String
  ic10471260: IC28037435234
  pe6416159: Pe81388412
}
input UpdateIn12743319Input {
  cl64010677: String
  id: ID!
  na13121605: String
  st97285675: String
  en6262250: String
  ci83825827: String
  st61999631: String
  de66827894: String
  st18370808: String
  op3452993: Int
  in43992751: String
  in88418543: String
  ti57061136: String
  ar89226604: Boolean
  la75757940: Float
  ln49010101: Float
}
type UpdateIn12743319Payload {
  cl64010677: String
  in98532332: In12743319
}
input UpdateIn12743319Us44827341Input {
  cl64010677: String
  id: ID!
  ro5651591: String
}
type UpdateIn12743319Us44827341Payload {
  cl64010677: String
  in7885687: In12743319Us44827341
}
input UpdateLo31830362Input {
  cl64010677: String
  id: ID!
  na13121605: String
  lo78149830: String
  ad36421314: String
  di80241846: String
  ge38334027: Float
  ge45596195: Float
  in44329409: Float
  in7313058: Float
  us78141759: Boolean
}
type UpdateLo31830362Payload {
  cl64010677: String
  lo93400274: Lo31830362
}
input UpdateMe37548318Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateMe37548318Payload {
  cl64010677: String
  me21551016: Me37548318
}
input UpdateMe25904200Input {
  cl64010677: String
  id: ID!
  ro5651591: String
}
type UpdateMe25904200Payload {
  cl64010677: String
  me93425130: Me25904200
}
input UpdateOb69073202Input {
  cl64010677: String
  id: ID!
  nu99206985: Int
  bo41275142: String
}
input UpdateOb69073202OperationalityInput {
  cl64010677: String
  id: ID!
  is76059106: Boolean!
}
type UpdateOb69073202OperationalityPayload {
  cl64010677: String
  pe6416159: Pe81388412
  ob55737262: Ob69073202
}
type UpdateOb69073202Payload {
  cl64010677: String
  ob55737262: Ob69073202
  do42594910: Do76642608
}
input UpdateOr51769208Input {
  cl64010677: String
  id: ID!
  qu70134088: String
}
type UpdateOr51769208Payload {
  cl64010677: String
  or13798486: Or51769208
}
input UpdateOr51769208Us44827341Input {
  cl64010677: String
  id: ID!
  us13562509: ID!
}
type UpdateOr51769208Us44827341Payload {
  cl64010677: String
  or13798486: Or51769208
  er85452588: String
}
input UpdateOr56512494Input {
  cl64010677: String
  id: ID!
  or92279086: String
  or45052357: String
  po69599994: String
  po73767570: String
  po15294071: String
}
type UpdateOr56512494Payload {
  cl64010677: String
  or84881531: Or56512494
}
input UpdatePe81388412Input {
  cl64010677: String
  id: ID!
  st84506348: String
  en6965241: String
}
type UpdatePe81388412Payload {
  cl64010677: String
  pe6416159: Pe81388412
  su63480918: String
  er85452588: String
  wa23850620: String
  in45134312: String
}
input UpdatePr6305523Input {
  cl64010677: String
  id: ID!
  pr40346269: String
  pr56963008: String
}
type UpdatePr6305523Payload {
  cl64010677: String
  pr10449942: Pr6305523
}
input UpdateSt9001101iesInput {
  cl64010677: String
  id: ID!
  st42493719: String
}
type UpdateSt9001101iesPayload {
  cl64010677: String
  ob55737262: Ob69073202
}
input UpdateTa34557648Input {
  cl64010677: String
  id: ID!
  ti22359276: String
  ta99029522: String
  co24804489: String
  ge84666105: String
  is14552457: Boolean
}
type UpdateTa34557648Payload {
  cl64010677: String
  ta45677779: Ta34557648
}
input UpdateUs44827341Input {
  cl64010677: String
  id: ID!
  fi45889694: String
  la48591314: String
  em7635361: String
  co11026667: String
}
type UpdateUs44827341Payload {
  cl64010677: String
  us71422177: Us44827341
}
input UpdateWe31448640Input {
  cl64010677: String
  id: ID!
  js62930677: String!
}
type UpdateWe31448640Payload {
  cl64010677: String
  we50181698: We31448640
  pe6416159: Pe81388412
}
input UpdateWo39743646Input {
  cl64010677: String
  id: ID!
  bo41275142: String
  se14469802: Int
  st72672469: String
  st18370808: String
  sp62296332: Int
  br28211757: String
  di45360760: String
  or84881531: ID
}
input UpdateWo39743646Or56512494Input {
  cl64010677: String
  id: ID!
  or1284175: ID
}
type UpdateWo39743646Or56512494Payload {
  cl64010677: String
  wo70541676: Wo39743646
}
type UpdateWo39743646Payload {
  cl64010677: String
  wo70541676: Wo39743646
}
input UploadDo18507649sInput {
  cl64010677: String
  id: ID!
}
type UploadDo18507649sPayload {
  cl64010677: String
  do42594910: Do76642608
  do35211570: Do76642608Build
  er85452588: String
}
input UploadIC280374352011Ma914423Input {
  cl64010677: String
  id: ID!
}
type UploadIC280374352011Ma914423Payload {
  cl64010677: String
  do42594910: Do76642608
  ic17062660: IC280374352011
  er85452588: String
}
type Us44827341 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  em7635361: String!
  fi45889694: String
  la48591314: String
  co11026667: String
  is44038920: Boolean
  la7986297: String
  ne70941519: Boolean
  ac24408163: [Ac10339026]
  ne74454458: In12743319
  in267573: [In12743319]
  me15958901: [Me25904200]
  ca3589904: Boolean
}
type Us44827341Connection {
  ed79758833: [Us44827341Edge]
  pa24440567: PageInfo!
}
type Us44827341Edge {
  no17534244: Us44827341
  cu58102045: String!
}
type We31448640 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  na13121605: String
  pr18457416: String
  pr42308928: String
  st18370808: String
  om58704807: String
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  do42594910: Do76642608
}
type Wo39743646 implements Node, Re17665062, Co68529874 {
  id: ID!
  ra52455944: Int!
  to39952341: String!
  ic30860072: Ic53116404
  co77824378: [Co5807770]
  in98532332: In12743319
  wo70541676: String
  sp1169787: String
  se14469802: Int
  st72672469: String
  st54257225: Us44827341
  st18370808: String!
  sp62296332: Int
  br28211757: String
  di45360760: String
  or84881531: Or56512494
  pe6416159: Pe81388412
  ac74199398: Ac10339026
  re38205043: String
  ga37136882: String
}
    GRAPHQL
    }
    let(:schema) {
      s = GraphQL::Schema.from_definition(schema_defn)
      s
    }
    let(:query_string) { <<-GRAPHQL
      query Co68529874UI_Co68529874RelayQL($id_0:ID!) {
        no17534244(id:$id_0) {
          id
          ...F4
        }
      }
      fragment F0 on Co5807770 {
        id
      }
      fragment F1 on Co5807770 {
        id
        ...F0
      }
      fragment F2 on Co5807770 {
        id
        ...F1
      }
      fragment F3 on Co68529874 {
        id
      }
      fragment F4 on Co68529874 {
        id
        co77824378 {
          ...F2
        }
        ...F3
      }
    GRAPHQL
    }

    it "validates ok" do
      error_messages = schema.validate(query_string).map(&:message)
      assert_equal [], error_messages
    end

  end
end
