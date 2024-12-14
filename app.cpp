#include <iostream>
#include <iomanip>
#include <cctype>
#include <windows.h>  
#include <tchar.h>  
#define _CRT_SECURE_NO_DEPRECATE
#define _CRT_SECURE_NO_WARNINGS
#pragma warning (disable : 4996)
#include <stdio.h>
#include <dbt.h>
#include <strsafe.h>
#include <Ntddcdrm.h>
#include <ntddscsi.h>
#include <winioctl.h>
#include <vector>

#pragma comment(lib, "user32.lib" )

// Função template para imprimir arrays de qualquer tipo
template <typename T, size_t N>
void printArray(const T(&arr)[N], const std::string& arrayName = "") {
    // Imprime o nome do array (se fornecido)
    if (!arrayName.empty()) {
        std::cout << arrayName << " [";
    }
    else {
        std::cout << "[";
    }

    // Imprime os elementos do array
    for (size_t i = 0; i < N; ++i) {
        // Converte o elemento para int se for um tipo de byte
        if constexpr (std::is_same_v<T, unsigned char> || std::is_same_v<T, char>) {
            std::cout << static_cast<int>(arr[i]);
        }
        else {
            std::cout << arr[i];
        }

        // Adiciona vírgula entre os elementos, exceto após o último
        if (i < N - 1) {
            std::cout << ", ";
        }
    }
    std::cout << "]" << std::endl;
}

void printHexDump(const unsigned char* data, size_t length) {
    const size_t bytesPerLine = 16;
    for (size_t i = 0; i < length; i += bytesPerLine) {
        // Imprime o endereço (offset)
        std::cout << std::setw(6) << std::setfill('0') << std::hex << i << "  ";

        // Imprime os bytes em hex
        for (size_t j = 0; j < bytesPerLine; j++) {
            if (i + j < length) {
                std::cout << std::setw(2) << (int)data[i + j] << " ";
            }
            else {
                // Caso não tenha mais bytes, preencher espaço vazio 
                std::cout << "   ";
            }
        }

        std::cout << " ";

        // Imprime a representação ASCII ao lado
        for (size_t j = 0; j < bytesPerLine; j++) {
            if (i + j < length) {
                unsigned char c = data[i + j];
                if (std::isprint(c)) {
                    std::cout << c;
                }
                else {
                    std::cout << ".";
                }
            }
            else {
                // Caso não tenha mais bytes
                std::cout << " ";
            }
        }

        std::cout << std::endl;
    }
}

// Função para converter MSF (Min, Sec, Frame) para LBA
static inline int MSFtoLBA(UCHAR M, UCHAR S, UCHAR F) {
    // A contagem de quadros do CD é de 75 frames por segundo
    // O LBA 0 é definido 2 segundos antes do primeiro setor de dados (isto é, LBA = MSF(00:02:00) = -150)
    // Fórmula: LBA = (M * 60 + S) * 75 + F - 150
    return ((int)M * 60 + (int)S) * 75 + (int)F - 150;
}

// Função para converter BCD em decimal
static UCHAR BcdToDec(UCHAR bcd) {
    return (UCHAR)((bcd >> 4) * 10 + (bcd & 0x0F));
}

// Lê a TOC do CD e retorna o último LBA do disco.
// Retorna -1 em caso de falha.
int getLastLBA(HANDLE hDevice) {
    CDROM_TOC toc;
    DWORD bytesReturned;

    BOOL result = DeviceIoControl(hDevice,
        IOCTL_CDROM_READ_TOC,
        NULL, 0,
        &toc, sizeof(toc),
        &bytesReturned,
        NULL);

    if (!result) {
        std::cerr << "Falha ao ler TOC do CD. Erro: " << GetLastError() << std::endl;
        return -1;
    }

    // A TOC contém [LastTrack - FirstTrack + 2] entradas:
    //  - Uma para cada faixa (de FirstTrack até LastTrack)
    //  - Uma para o lead-out (TrackNumber = 0xAA)
    // Vamos procurar a entrada com TrackNumber = 0xAA
    TRACK_DATA leadOut;
    bool foundLeadOut = false;

    int totalEntries = toc.LastTrack - toc.FirstTrack + 2;
    for (int i = 0; i < totalEntries; i++) {
        if (toc.TrackData[i].TrackNumber == 0xAA) {
            leadOut = toc.TrackData[i];
            foundLeadOut = true;
            break;
        }
    }

    if (!foundLeadOut) {
        std::cerr << "Não foi possível encontrar a entrada do lead-out no TOC." << std::endl;
        return -1;
    }

    // Converter BCD para decimal
    auto BcdToDec = [](UCHAR bcd) {
        return (UCHAR)((bcd >> 4) * 10 + (bcd & 0x0F));
        };

    UCHAR M = BcdToDec(leadOut.Address[1]);
    UCHAR S = BcdToDec(leadOut.Address[2]);
    UCHAR F = BcdToDec(leadOut.Address[3]);

    // Converter MSF para LBA
    int lastLBA = ((int)M * 60 + (int)S) * 75 + (int)F - 150;

    return lastLBA;
}


// Função para ler um setor do CD.
// Se abortOnError = true, retorna false em caso de erro.
// Se abortOnError = false, preenche buf com zeros em caso de erro e retorna true.
bool readSector(HANDLE hDevice, unsigned int LBA, UCHAR* buf, bool abortOnError) {
    UCHAR cdb[12];
    ZeroMemory(cdb, sizeof(cdb));
    cdb[0] = 0xBE; // READ CD
    cdb[1] = 0x00; // Tipo de setor esperado (0x00 para dados)
    // Preenche LBA
    cdb[2] = (UCHAR)((LBA >> 24) & 0xFF);
    cdb[3] = (UCHAR)((LBA >> 16) & 0xFF);
    cdb[4] = (UCHAR)((LBA >> 8) & 0xFF);
    cdb[5] = (UCHAR)(LBA & 0xFF);

    // Lê 1 bloco
    cdb[6] = 0x00;
    cdb[7] = 0x00;
    cdb[8] = 0x01;

    // Solicita Sync+Header+UserData+EDC/ECC
    cdb[9] = 0xF8;
    cdb[10] = 0x00;
    cdb[11] = 0x00;

    struct sptd_with_sense {
        SCSI_PASS_THROUGH_DIRECT s;
        UCHAR sense[128];
    } sptd;

    ZeroMemory(&sptd, sizeof(sptd));
    sptd.s.Length = sizeof(sptd.s);
    sptd.s.CdbLength = sizeof(cdb);
    sptd.s.DataIn = SCSI_IOCTL_DATA_IN;
    sptd.s.TimeOutValue = 30;
    sptd.s.DataBuffer = buf;
    sptd.s.DataTransferLength = 2352;
    sptd.s.SenseInfoLength = sizeof(sptd.sense);
    sptd.s.SenseInfoOffset = offsetof(struct sptd_with_sense, sense);
    memcpy(sptd.s.Cdb, cdb, sizeof(cdb));

    DWORD ioctl_bytes;
    BOOL ioctl_rv = DeviceIoControl(hDevice,
        IOCTL_SCSI_PASS_THROUGH_DIRECT,
        &sptd, sizeof(sptd),
        &sptd, sizeof(sptd),
        &ioctl_bytes, NULL);

    if (ioctl_rv == 0 || sptd.s.ScsiStatus != 0) {
        std::cerr << "Falha ao ler setor " << LBA << ". Erro: " << GetLastError() << " SCSI Status: " << (int)sptd.s.ScsiStatus << std::endl;
        if (abortOnError) {
            return false;
        }
        else {
            // Preenche com zeros
            ZeroMemory(buf, 2352);
            return true;
        }
    }

    return true;
}


// Função para ler um setor usando READ(10) (CDB 0x28)
// Lê 1 bloco (tamanho típico 2048 bytes) no LBA especificado
bool readSectorUsingREAD10(HANDLE hDevice, DWORD LBA, UCHAR* buffer, DWORD bufferSize) {
    // Assumindo 1 setor = 2048 bytes
    // Ajuste se necessário
    DWORD sectorSize = 2048;
    if (bufferSize < sectorSize) {
        return false; // Buffer muito pequeno
    }

    UCHAR cdb[10];
    ZeroMemory(cdb, sizeof(cdb));
    cdb[0] = 0x28; // READ(10)
    cdb[2] = (UCHAR)((LBA >> 24) & 0xFF);
    cdb[3] = (UCHAR)((LBA >> 16) & 0xFF);
    cdb[4] = (UCHAR)((LBA >> 8) & 0xFF);
    cdb[5] = (UCHAR)(LBA & 0xFF);
    cdb[8] = 0x01; // Numero de setores a ler = 1

    struct sptd_with_sense {
        SCSI_PASS_THROUGH_DIRECT s;
        UCHAR sense[32];
    } sptd;

    ZeroMemory(&sptd, sizeof(sptd));
    sptd.s.Length = sizeof(sptd.s);
    sptd.s.CdbLength = sizeof(cdb);
    sptd.s.DataIn = SCSI_IOCTL_DATA_IN;
    sptd.s.TimeOutValue = 30;
    sptd.s.DataBuffer = buffer;
    sptd.s.DataTransferLength = sectorSize;
    sptd.s.SenseInfoLength = sizeof(sptd.sense);
    sptd.s.SenseInfoOffset = offsetof(struct sptd_with_sense, sense);
    memcpy(sptd.s.Cdb, cdb, sizeof(cdb));

    DWORD bytesReturned;
    BOOL result = DeviceIoControl(hDevice,
        IOCTL_SCSI_PASS_THROUGH_DIRECT,
        &sptd, sizeof(sptd),
        &sptd, sizeof(sptd),
        &bytesReturned,
        NULL);

    if (!result || sptd.s.ScsiStatus != 0) {
        return false;
    }

    return true;
}

// Função para obter o total de setores do CD ISO9660 usando o Volume Descriptor no LBA 16
// Retorna -1 em caso de erro ou se não for ISO9660.
int getTotalSectorsFromISO9660(HANDLE hDevice) {
    UCHAR buffer[2048];
    if (!readSectorUsingREAD10(hDevice, 16, buffer, sizeof(buffer))) {
        std::cerr << "Falha ao ler setor 16 do ISO9660." << std::endl;
        return -1;
    }

    // Verifica se é um Primary Volume Descriptor (tipo = 1 em offset 0x00)
    if (buffer[0] != 1) {
        std::cerr << "Setor 16 não é um PVD (Primary Volume Descriptor) válido." << std::endl;
        return -1;
    }

    // ISO9660 PVD:
    // Offset 80-83 (little-endian) contém o número de blocos lógicos
    // Em ISO9660, geralmente o tamanho do bloco lógico é 2048 bytes.
    // O total de blocos lógicos é armazenado em 4 bytes LE:
    uint32_t totalBlocks = *(uint32_t*)&buffer[80];

    return (int)totalBlocks;
}

// Função para obter o tamanho LBA usando SCSI READ CAPACITY (0x25)
int getTotalSectorsFromReadCapacity(HANDLE hDevice) {
    UCHAR cdb[10];
    ZeroMemory(cdb, sizeof(cdb));
    cdb[0] = 0x25; // READ CAPACITY(10)

    UCHAR data[8];
    ZeroMemory(data, sizeof(data));

    struct sptd_with_sense {
        SCSI_PASS_THROUGH_DIRECT s;
        UCHAR sense[32];
    } sptd;
    ZeroMemory(&sptd, sizeof(sptd));
    sptd.s.Length = sizeof(sptd.s);
    sptd.s.CdbLength = sizeof(cdb);
    sptd.s.DataIn = SCSI_IOCTL_DATA_IN;
    sptd.s.TimeOutValue = 30;
    sptd.s.DataBuffer = data;
    sptd.s.DataTransferLength = sizeof(data);
    sptd.s.SenseInfoLength = sizeof(sptd.sense);
    sptd.s.SenseInfoOffset = offsetof(struct sptd_with_sense, sense);
    memcpy(sptd.s.Cdb, cdb, sizeof(cdb));

    DWORD bytesReturned;
    BOOL result = DeviceIoControl(hDevice,
        IOCTL_SCSI_PASS_THROUGH_DIRECT,
        &sptd, sizeof(sptd),
        &sptd, sizeof(sptd),
        &bytesReturned,
        NULL);

    if (!result || sptd.s.ScsiStatus != 0) {
        std::cerr << "Falha no READ CAPACITY." << std::endl;
        return -1;
    }

    // Data[0..3] = last logical block address (big-endian)
    // Data[4..7] = block length in bytes (big-endian)
    uint32_t lastLBA = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
    // uint32_t blockSize = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];

    // Total de setores = lastLBA + 1
    return (int)(lastLBA + 1);
}


int getTotalSectorsFromFullToc(HANDLE hDevice) {
    /*LPCTSTR drive = _T("\\\\.\\E:");

    HANDLE hDevice = CreateFile(drive, GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
        OPEN_EXISTING, 0, NULL);
    if (hDevice == INVALID_HANDLE_VALUE) {
        printf("Erro ao abrir dispositivo: %d\n", GetLastError());
        return 1;
    }*/

    CDROM_READ_TOC_EX tocInput;
    ZeroMemory(&tocInput, sizeof(tocInput));
    tocInput.Format = CDROM_READ_TOC_EX_FORMAT_FULL_TOC;
    tocInput.Msf = 0; // Retornar endereços em BCD MSF
    tocInput.SessionTrack = 0;

    BYTE buffer[0x1000];
    ZeroMemory(buffer, sizeof(buffer));

    DWORD bytesReturned = 0;
    BOOL result = DeviceIoControl(hDevice,
        IOCTL_CDROM_READ_TOC_EX,
        &tocInput, sizeof(tocInput),
        buffer, sizeof(buffer),
        &bytesReturned,
        NULL);
    if (!result) {
        printf("Falha ao ler FULL TOC. Erro: %d\n", GetLastError());
        CloseHandle(hDevice);
        return 1;
    }

    PCDROM_TOC_FULL_TOC_DATA fullToc = (PCDROM_TOC_FULL_TOC_DATA)buffer;
    ULONG dataLength = (fullToc->Length[0] << 8) | fullToc->Length[1];
    ULONG entryCount = dataLength / sizeof(CDROM_TOC_FULL_TOC_DATA_BLOCK);

    PCDROM_TOC_FULL_TOC_DATA_BLOCK blocks = (PCDROM_TOC_FULL_TOC_DATA_BLOCK)(fullToc->Descriptors);

    if (entryCount == 0) {
        printf("Nenhum dado retornado no FULL TOC.\n");
        CloseHandle(hDevice);
        return 1;
    }

    // Identificar se o CD é de áudio ou dados
    // Procurar a primeira faixa válida (1 a 99 em BCD)
    int firstTrackIndex = -1;
    for (ULONG i = 0; i < entryCount; i++) {
        UCHAR point = blocks[i].Point;
        UCHAR decPoint = BcdToDec(point);
        if (decPoint >= 1 && decPoint <= 99) {
            firstTrackIndex = (int)i;
            break;
        }
    }

    if (firstTrackIndex < 0) {
        printf("Não foi possível encontrar a primeira faixa.\n");
        CloseHandle(hDevice);
        return 1;
    }

    bool isDataCD = (blocks[firstTrackIndex].Control & 0x04) != 0;
    bool isAudioCD = !isDataCD;

    // Verificar se é multi-sessão
    std::vector<UCHAR> sessionsFound;
    for (ULONG i = 0; i < entryCount; i++) {
        UCHAR sess = blocks[i].SessionNumber;
        if (std::find(sessionsFound.begin(), sessionsFound.end(), sess) == sessionsFound.end()) {
            sessionsFound.push_back(sess);
        }
    }
    bool isMultisession = (sessionsFound.size() > 1);

    // Encontrar o lead-out usando o POINT = 0xA2 (162 decimal)
    int leadOutIndex = -1;
    for (int i = (int)entryCount - 1; i >= 0; i--) {
        if (blocks[i].Point == 0xA2) {
            leadOutIndex = i;
            break;
        }
    }

    if (leadOutIndex < 0) {
        printf("Não foi possível encontrar o lead-out.\n");
        CloseHandle(hDevice);
        return 1;
    }

    UCHAR M = BcdToDec(blocks[leadOutIndex].Msf[0]);
    UCHAR S = BcdToDec(blocks[leadOutIndex].Msf[1]);
    UCHAR F = BcdToDec(blocks[leadOutIndex].Msf[2]);

    int lastLBA = MSFtoLBA(M, S, F);

    //printf("Tipo de CD: %s\n", isDataCD ? "Dados (ISO9660)" : "Audio");
    //printf("É multi-sessão? %s\n", isMultisession ? "Sim" : "Não");
    //printf("Último LBA do disco: %d\n", lastLBA);

   // CloseHandle(hDevice);
    return lastLBA;
}

int getLBAtest() {
    LPCTSTR drive = _T("\\\\.\\E:");

    HANDLE hDevice = CreateFile(drive, GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
        OPEN_EXISTING, 0, NULL);
    if (hDevice == INVALID_HANDLE_VALUE) {
        std::cerr << "Falha ao abrir dispositivo. Erro: " << GetLastError() << std::endl;
        return 1;
    }

    // Primeiro, tentamos obter o total de setores via ISO9660 (se for um CD de dados):
    int totalSectorsISO = getTotalSectorsFromISO9660(hDevice);
    if (totalSectorsISO > 0) {
        std::cout << "Total de setores (via ISO9660): " << totalSectorsISO << std::endl;
    }
    else {
        std::cout << "Não foi possível obter via ISO9660 ou não é um CD de dados." << std::endl;
    }

    // Agora, obter via SCSI READ CAPACITY:
    int totalSectorsCapacity = getTotalSectorsFromReadCapacity(hDevice);
    if (totalSectorsCapacity > 0) {
        std::cout << "Total de setores (via READ CAPACITY): " << totalSectorsCapacity << std::endl;
    }
    else {
        std::cout << "Não foi possível obter via READ CAPACITY." << std::endl;
    }

    int totalSectorsToc = getTotalSectorsFromFullToc(hDevice);
    if (totalSectorsToc > 0) {
        std::cout << "Total de setores (via FULL TOC): " << totalSectorsToc << std::endl;
    }
    else {
        std::cout << "Não foi possível obter via FULL TOCY." << std::endl;
    }

    CloseHandle(hDevice);
    return 0;
}


//funciona mais não é o ideal
int getTotalSectorsFromGeometry() {
    LPCTSTR drive = _T("\\\\.\\E:");  // Replace with the drive letter of your CD/DVD drive
    DISK_GEOMETRY_EX diskGeometryEx = { 0 };
    DWORD bytesReturned = 0;
    BOOL result;

    HANDLE hDevice = CreateFile(drive, GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE, // Use both shares to avoid access issues
        NULL,
        OPEN_EXISTING,
        0,
        NULL);
    if (hDevice == INVALID_HANDLE_VALUE) {
        printf("Error opening the device: %d\n", GetLastError());
        return 1;
    }

    // Query the extended drive geometry
    result = DeviceIoControl(hDevice,
        IOCTL_DISK_GET_DRIVE_GEOMETRY_EX,
        NULL,
        0,
        &diskGeometryEx,
        sizeof(diskGeometryEx),
        &bytesReturned,
        NULL);

    if (!result) {
        printf("Error getting drive geometry: %d\n", GetLastError());
        CloseHandle(hDevice);
        return 1;
    }

    // Extract sector size
    DWORD sectorSize = diskGeometryEx.Geometry.BytesPerSector;

    // Calculate the total number of sectors:
    // total sectors = total bytes / bytes per sector
    ULONGLONG totalSectors = diskGeometryEx.DiskSize.QuadPart / sectorSize;

    printf("Sector Size: %lu bytes\n", sectorSize);
    printf("Total Sectors: %llu\n", totalSectors);
    printf("LBA Size: %llu\n", totalSectors);

    CloseHandle(hDevice);
    return 0;
}


int main() {
    // Abre o dispositivo (drive de CD)
    HANDLE hDevice = CreateFile(_T("\\\\.\\E:"), GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, NULL);

    if (hDevice == INVALID_HANDLE_VALUE) {
        std::cerr << "Falha ao acessar drive. Erro: " << GetLastError() << std::endl;
        return 1;
    }

    int lastLBA = getTotalSectorsFromISO9660(hDevice);
    if (lastLBA < 0) {
        std::cerr << "Não foi possível determinar o último LBA do disco." << std::endl;
        CloseHandle(hDevice);
        return 1;
    }

    std::cout << "Último LBA do disco: " << lastLBA << std::endl;

    //return 0;

    // Abrir arquivo de saída
    FILE* fp = fopen("C:\\Users\\isaque.neves\\source\\repos\\ConsoleApplication1\\faixa1.bin", "wb");
    if (!fp) {
        std::cerr << "Não foi possível criar arquivo faixa1.bin" << std::endl;
        CloseHandle(hDevice);
        return 1;
    }

    // Decide comportamento em caso de falha
    bool abortOnError = false; // false = preenche com zeros, true = aborta ao primeiro erro

    UCHAR buf[2352];
    for (int LBA = 0; LBA <= lastLBA; LBA++) {
        if (!readSector(hDevice, (unsigned int)LBA, buf, abortOnError)) {
            // Se o abortOnError = true, este retorno indica falha
            std::cerr << "Abortando operação no LBA " << LBA << std::endl;
            fclose(fp);
            CloseHandle(hDevice);
            return 1;
        }

        // buf agora contém o setor (ou zeros em caso de erro se abortOnError = false)
        size_t written = fwrite(buf, 1, sizeof(buf), fp);
        if (written != sizeof(buf)) {
            std::cerr << "Falha ao escrever no arquivo no LBA " << LBA << std::endl;
            fclose(fp);
            CloseHandle(hDevice);
            return 1;
        }

        // Opcional: imprimir progresso
        if (LBA % 1000 == 0) {
            std::cout << "Lendo LBA " << LBA << "/" << lastLBA << std::endl;
        }
    }

    fclose(fp);
    CloseHandle(hDevice);
    std::cout << "Extração concluída com sucesso. Arquivo: faixa1.bin" << std::endl;
    return 0;
}

int dumpCDRawTest()
{
    HANDLE fh;
    DWORD ioctl_bytes;
    BOOL ioctl_rv;
   // UCHAR cdb[] = { 0xBE, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0 };

    // Aqui definimos o LBA de forma dinâmica
    // Por exemplo, queremos ler o setor 1000 (0x3E8):
    unsigned int LBA = 10000;
    printf("LBA: %d\n", LBA);
       

    UCHAR cdb[12];
    ZeroMemory(cdb, sizeof(cdb));
    cdb[0] = 0xBE; // READ CD
    cdb[1] = 0x00; // Tipo de setor esperado (0x00 para dados)
    // Preenche o LBA nos bytes corretos do CDB (2..5)
    cdb[2] = (UCHAR)((LBA >> 24) & 0xFF);
    cdb[3] = (UCHAR)((LBA >> 16) & 0xFF);
    cdb[4] = (UCHAR)((LBA >> 8) & 0xFF);
    cdb[5] = (UCHAR)(LBA & 0xFF);

    cdb[6] = 0x00; // Tamanho da transferência em blocos (MSB)
    cdb[7] = 0x00;
    cdb[8] = 0x01; // 1 bloco

    cdb[9] = 0xF8; // Solicita retornar Sync+Header+UserData+EDC/ECC
    cdb[10] = 0x00;
    cdb[11] = 0x00;

    printArray(cdb, "cdb");
    UCHAR buf[2352];
    struct sptd_with_sense
    {
        SCSI_PASS_THROUGH_DIRECT s;
        UCHAR sense[128];
    } sptd;

    fh = CreateFile(_T("\\\\.\\E:"), GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, NULL);


    if (fh == INVALID_HANDLE_VALUE) {
        printf("Falha ao ler setor via SPTI.Erro: %d", GetLastError());
        return 1;
    }

    std::cout << "CreateFile " << fh << std::endl;

    memset(&sptd, 0, sizeof(sptd));
    sptd.s.Length = sizeof(sptd.s);
    sptd.s.CdbLength = sizeof(cdb);
    sptd.s.DataIn = SCSI_IOCTL_DATA_IN;
    sptd.s.TimeOutValue = 30;
    sptd.s.DataBuffer = buf;
    sptd.s.DataTransferLength = sizeof(buf);
    sptd.s.SenseInfoLength = sizeof(sptd.sense);
    sptd.s.SenseInfoOffset = offsetof(struct sptd_with_sense, sense);
    memcpy(sptd.s.Cdb, cdb, sizeof(cdb));

    ioctl_rv = DeviceIoControl(fh, IOCTL_SCSI_PASS_THROUGH_DIRECT, &sptd,
        sizeof(sptd), &sptd, sizeof(sptd), &ioctl_bytes, NULL);

    if (sptd.s.ScsiStatus != 0) {
        // Houve erro no comando SCSI
        printf("SCSI Status: %d\n", sptd.s.ScsiStatus);
        // Verifique dados de sense em sptd.sense
    }

    if (ioctl_rv == 0) {
        printf("Falha ao ler setor via SPTI.Erro: %d", GetLastError());        
        return 1;
    }

    std::cout << "ioctl_rv " << ioctl_rv << std::endl;

    // Agora, use a função printHexDump para imprimir os bytes do buffer em formato "hex dump".
    printHexDump(buf, sizeof(buf));

    CloseHandle(fh);
    // Apenas para segurar a tela.
   // getchar();

    //printf("rc: %d\n", ioctl_rv);
    //// formato "%02hhX" | "%hhX"
    //int i;
    //printf("\nSync, Addr, Mode (16 bytes)\n");
    //for (i = 0; i < 16; i++) {
    //    printf("%02hhX", buf[i]); //this data comes back fine
    //}
    //printf("\nData (2048 bytes)\n");
    //for (i = 16; i < 16 + 2048; i++) {
    //    printf("%02hhX", buf[i]); //this data comes back fine
    //}
    //printf("\nED, RZ, EC (288 bytes)\n");
    //for (i = 16 + 2048; i < 16 + 2048 + 288; i++) {
    //    printf("%02hhX", buf[i]); //this data comes back wrong
    //}
    //printf("\nC2, Sub (392 bytes)\n");
    //for (i = 16 + 2048 + 288; i < 2744; i++) {
    //    printf("%02hhX", buf[i]); //not sure if this is right or not
    //}
    ////dumb code to block terminal from closing
    //char str[80];
    //fgets(str, 10, stdin);


    

    return 0;
}


int openDoor()
{
    std::cout << "WM_DEVICECHANGE: " << WM_DEVICECHANGE << std::endl;
    //std::cout << "PDEV_BROADCAST_HDR : " << PDEV_BROADCAST_HDR << std::endl;
    std::cout << "IOCTL_SCSI_PASS_THROUGH   : " << SCSI_IOCTL_DATA_IN << std::endl;
    
    DWORD dwBytes;
    HANDLE hCdRom = CreateFile(_T("\\\\.\\E:"), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    if (hCdRom == INVALID_HANDLE_VALUE)
    {
        _tprintf(_T("Error: %x"), GetLastError());
        return 1;
    }
   std::cout << "IOCTL_STORAGE_EJECT_MEDIA: " << IOCTL_STORAGE_EJECT_MEDIA << std::endl;
   std::cout << "IOCTL_STORAGE_LOAD_MEDIA: " << IOCTL_STORAGE_LOAD_MEDIA << std::endl;

   
    // Open the door:  
    DeviceIoControl(hCdRom, IOCTL_STORAGE_EJECT_MEDIA, NULL, 0, NULL, 0, &dwBytes, NULL);
    std::cout << "dwBytes: " << dwBytes << std::endl;
    Sleep(1000);

    // Close the door:  
    DeviceIoControl(hCdRom, IOCTL_STORAGE_LOAD_MEDIA, NULL, 0, NULL, 0, &dwBytes, NULL);

    CloseHandle(hCdRom);
}