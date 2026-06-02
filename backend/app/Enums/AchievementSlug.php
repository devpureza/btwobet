<?php

namespace App\Enums;

enum AchievementSlug: string
{
    case PrimeiroPalpite = 'primeiro-palpite';
    case EmCampo = 'em-campo';
    case PlacarNaMosca = 'placar-na-mosca';
    case TrioPerfeito = 'trio-perfeito';
    case Pontuador = 'pontuador';
    case NoTopo = 'no-topo';
    case Podio = 'podio';
    case PresencaConfirmada = 'presenca-confirmada';
    case BemVindo = 'bem-vindo';
    case PerfilComCara = 'perfil-com-cara';
    case DezPalpites = 'dez-palpites';
    case MeiaCenturia = 'meia-centuria';
    case Maratonista = 'maratonista';
    case FaseGruposFirme = 'fase-grupos-firme';
    case MataMataChegou = 'mata-mata-chegou';
    case ArtilheiroDeAcertos = 'artilheiro-de-acertos';
    case SequenciaDeResultado = 'sequencia-de-resultado';
    case DuplaExata = 'dupla-exata';
    case EmpateCerteiro = 'empate-certeiro';
    case Zerinho = 'zerinho';
    case GoleadaPrevista = 'goleada-prevista';
    case Top10 = 'top-10';
    case ViceCampeao = 'vice-campeao';
    case CampeaoDoBolao = 'campeao-do-bolao';
    case Recuperacao = 'recuperacao';
    case SemanaAtiva = 'semana-ativa';
    case SemMissNoFds = 'sem-miss-no-fds';
    case EstreiaDaCopa = 'estreia-da-copa';
    case JogoDecisivo = 'jogo-decisivo';
    case GrandeFinal = 'grande-final';
    case UnderdogDoDia = 'underdog-do-dia';
    case Oraculo = 'oraculo';
    case InvictoNoTopo = 'invicto-no-topo';
}
